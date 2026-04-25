import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/db_core/db/main_store.dart';
import 'package:hoplixi/db_core/old/main_store_manager.dart';
import 'package:hoplixi/db_core/old/models/db_errors.dart';
import 'package:hoplixi/db_core/old/models/db_state.dart';
import 'package:hoplixi/db_core/old/models/dto/main_store_dto.dart';
import 'package:hoplixi/db_core/old/provider/main_store_close_sync_controller.dart';
import 'package:hoplixi/db_core/old/provider/main_store_runtime_provider.dart';
import 'package:hoplixi/db_core/old/provider/main_store_session_contract.dart';
import 'package:hoplixi/db_core/old/provider/main_store_storage_controller.dart';
import 'package:hoplixi/db_core/old/services/main_store_maintenance_service.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';

export 'package:hoplixi/db_core/old/provider/main_store_backup_models.dart';

final mainStoreProvider =
    AsyncNotifierProvider<MainStoreAsyncNotifier, DatabaseState>(
      MainStoreAsyncNotifier.new,
    );

final mainStoreStateProvider = FutureProvider<DatabaseState>((ref) async {
  return ref.watch(mainStoreProvider.future);
});

final mainStoreManagerProvider = FutureProvider<MainStoreManager?>((ref) async {
  final asyncState = await ref.watch(mainStoreProvider.future);
  if (!asyncState.isOpen) {
    return null;
  }

  return ref.watch(mainStoreManagerRuntimeProvider.future);
});

final dataUpdateStreamProvider = Provider<Stream<void>>((ref) {
  final managerAsync = ref.watch(mainStoreManagerProvider);

  return managerAsync.maybeWhen(
    data: (manager) {
      if (manager != null && manager.currentStore != null) {
        return manager.currentStore!.watchDataChanged().skip(1);
      }
      return const Stream.empty();
    },
    orElse: () => const Stream.empty(),
  );
});

class MainStoreAsyncNotifier extends AsyncNotifier<DatabaseState> {
  static const String _logTag = 'MainStoreAsyncNotifier';
  static const Duration _errorResetDelay = Duration(seconds: 10);

  late final MainStoreManager _manager;
  late final MainStoreMaintenanceService _maintenanceService;
  late final MainStoreStorageController _storageController;
  late final MainStoreCloseSyncController _closeSyncController;

  Timer? _errorResetTimer;
  Completer<void>? _operationLock;

  DatabaseState get _currentState {
    return state.value ?? const DatabaseState(status: DatabaseStatus.idle);
  }

  MainStoreSessionBridge get _sessionBridge => MainStoreSessionBridge(
    readState: () => _currentState,
    setState: _setState,
    setErrorState: _setErrorState,
  );

  void _setState(DatabaseState newState) {
    state = AsyncValue.data(newState);
  }

  void _setErrorState(DatabaseState errorState) {
    _cancelErrorResetTimer();
    _setState(errorState);
    _scheduleErrorReset();
  }

  void _scheduleErrorReset() {
    _errorResetTimer = Timer(_errorResetDelay, () {
      if (_currentState.hasError &&
          _currentState.status == DatabaseStatus.error) {
        logInfo('Автоматический сброс состояния ошибки до idle', tag: _logTag);
        _setState(const DatabaseState(status: DatabaseStatus.idle));
      }
    });
  }

  void _cancelErrorResetTimer() {
    _errorResetTimer?.cancel();
    _errorResetTimer = null;
  }

  Future<void> _acquireLock() async {
    while (_operationLock != null) {
      logInfo('Ожидание завершения предыдущей операции...', tag: _logTag);
      await _operationLock!.future;
    }
    _operationLock = Completer<void>();
  }

  void _releaseLock() {
    _operationLock?.complete();
    _operationLock = null;
  }

  Ref get _ref => ref;

  @override
  Future<DatabaseState> build() async {
    logInfo('MainStoreAsyncNotifier initialized', tag: _logTag);

    _manager = await ref.read(mainStoreManagerRuntimeProvider.future);
    _maintenanceService = ref.read(mainStoreMaintenanceServiceProvider);
    _storageController = ref.read(mainStoreStorageControllerProvider);
    _closeSyncController = ref.read(mainStoreCloseSyncControllerProvider);

    ref.onDispose(() {
      _cancelErrorResetTimer();
    });

    return const DatabaseState(status: DatabaseStatus.idle);
  }

  Future<bool> createStore(CreateStoreDto dto) async {
    await _acquireLock();

    try {
      logInfo('Creating store: ${dto.name}', tag: _logTag);

      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      final result = await _manager.createStore(dto);

      return result.fold(
        (storeInfo) {
          _setState(
            DatabaseState(
              path: _manager.currentStorePath,
              name: storeInfo.name,
              status: DatabaseStatus.open,
              modifiedAt: storeInfo.modifiedAt,
            ),
          );
          _closeSyncController.startTracking(
            initialModifiedAt: storeInfo.modifiedAt,
            forceUpload: true,
          );

          logInfo(
            'Store created successfully: ${storeInfo.name}',
            tag: _logTag,
          );
          unawaited(_runStartupCleanup());
          return true;
        },
        (error) {
          _setErrorState(
            DatabaseState(status: DatabaseStatus.error, error: error),
          );

          logError('Failed to create store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (error, stackTrace) {
      logError(
        'Unexpected error creating store: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setErrorState(
        DatabaseState(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при создании хранилища: $error',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );
      return false;
    } finally {
      _releaseLock();
    }
  }

  Future<bool> openStore(OpenStoreDto dto) {
    return _openStore(dto, allowMigration: false);
  }

  Future<bool> openStoreWithMigration(OpenStoreDto dto) {
    return _openStore(dto, allowMigration: true);
  }

  void setOpenFailure(DatabaseError error) {
    _setErrorState(_buildOpenFailureState(error));
  }

  void markOpeningStarted({String? path, String? name}) {
    _setState(
      _currentState.copyWith(
        path: path ?? _currentState.path,
        name: name ?? _currentState.name,
        status: DatabaseStatus.opening,
        error: null,
      ),
    );
  }

  Future<bool> _openStore(
    OpenStoreDto dto, {
    required bool allowMigration,
  }) async {
    await _acquireLock();

    try {
      logInfo('Opening store at: ${dto.path}', tag: _logTag);

      markOpeningStarted(path: dto.path);

      final result = await _manager.openStore(
        dto,
        allowMigration: allowMigration,
      );

      return result.fold(
        (storeInfo) {
          _setState(
            DatabaseState(
              path: _manager.currentStorePath,
              name: storeInfo.name,
              status: DatabaseStatus.open,
              modifiedAt: storeInfo.modifiedAt,
            ),
          );
          _closeSyncController.startTracking(
            initialModifiedAt: storeInfo.modifiedAt,
          );

          logInfo('Store opened successfully: ${storeInfo.name}', tag: _logTag);
          unawaited(_runStartupCleanup());
          return true;
        },
        (error) {
          _setErrorState(_buildOpenFailureState(error));
          logError('Failed to open store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (error, stackTrace) {
      logError(
        'Unexpected error opening store: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setErrorState(
        _buildOpenFailureState(
          DatabaseError.unknown(
            message: 'Неожиданная ошибка при открытии хранилища: $error',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );
      return false;
    } finally {
      _releaseLock();
    }
  }

  Future<bool> closeStore() async {
    await _acquireLock();
    DatabaseState? openStateBeforeClose;

    try {
      _ref.read(closeStoreSyncStatusProvider.notifier).clear();
      logInfo('Closing store', tag: _logTag);

      if (!_currentState.isOpen) {
        logWarning('Store is not open, cannot close', tag: _logTag);
        return false;
      }

      openStateBeforeClose = _currentState;
      final decryptedPathBeforeClose = await _storageController
          .getDecryptedAttachmentsPath(
            state: _currentState,
            manager: _manager,
            maintenanceService: _maintenanceService,
            logTag: _logTag,
          );

      try {
        await _tryUploadSnapshotBeforeClose(
          onCloseFlowRequired: () {
            _setState(
              openStateBeforeClose!.copyWith(
                status: DatabaseStatus.closingSync,
                error: null,
              ),
            );
          },
        );
      } catch (error, stackTrace) {
        final canCloseWithoutSync = await _shouldAllowCloseWithoutSyncFailure(
          error,
        );
        if (canCloseWithoutSync) {
          logWarning(
            'Snapshot sync before close failed in auto-upload mode due to recoverable network error. Closing store without cloud upload.',
            tag: _logTag,
            data: <String, dynamic>{
              'errorType': error.runtimeType.toString(),
              'error': error.toString(),
            },
          );
          _ref.read(closeStoreSyncStatusProvider.notifier).clear();
        } else {
          final closeSyncError = _buildCloseSyncFailure(
            error,
            stackTrace: stackTrace,
          );
          _setState(
            openStateBeforeClose.copyWith(
              status: DatabaseStatus.open,
              error: closeSyncError,
            ),
          );
          _ref.read(closeStoreSyncStatusProvider.notifier).clear();
          return false;
        }
      }

      final result = await _manager.closeStore();

      final isClosed = result.fold((_) => true, (error) {
        _setState(
          openStateBeforeClose!.copyWith(
            status: DatabaseStatus.open,
            error: error,
          ),
        );

        logError('Failed to close store: ${error.message}', tag: _logTag);
        return false;
      });

      if (!isClosed) {
        _ref.read(closeStoreSyncStatusProvider.notifier).clear();
        return false;
      }

      await _storageController.cleanupDecryptedAttachments(
        maintenanceService: _maintenanceService,
        dirPath: decryptedPathBeforeClose,
      );
      _closeSyncController.resetTracking();

      _setState(const DatabaseState(status: DatabaseStatus.closed));
      _setState(const DatabaseState(status: DatabaseStatus.idle));
      _ref.read(closeStoreSyncStatusProvider.notifier).clear();

      logInfo('Store closed successfully', tag: _logTag);
      return true;
    } catch (error, stackTrace) {
      logError(
        'Unexpected error closing store: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setState(
        (openStateBeforeClose ?? _currentState).copyWith(
          status: openStateBeforeClose != null
              ? DatabaseStatus.open
              : DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при закрытии хранилища: $error',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );
      _ref.read(closeStoreSyncStatusProvider.notifier).clear();
      return false;
    } finally {
      _releaseLock();
    }
  }

  Future<void> lockStore({bool skipSnapshotSync = false}) async {
    if (!_currentState.isOpen) {
      logWarning('Store is not open, cannot lock', tag: _logTag);
      return;
    }

    _ref.read(closeStoreSyncStatusProvider.notifier).clear();
    logInfo('Locking store', tag: _logTag);

    final currentPath = _currentState.path;
    final currentName = _currentState.name;
    final decryptedPathBeforeLock = await _storageController
        .getDecryptedAttachmentsPath(
          state: _currentState,
          manager: _manager,
          maintenanceService: _maintenanceService,
          logTag: _logTag,
        );

    if (!skipSnapshotSync) {
      await _tryUploadSnapshotBeforeClose();
    }

    final closeResult = await _manager.closeStore();
    closeResult.fold((_) => null, (error) {
      logError(
        'Failed to close store during lock: ${error.message}',
        tag: _logTag,
      );
      return null;
    });

    await _storageController.cleanupDecryptedAttachments(
      maintenanceService: _maintenanceService,
      dirPath: decryptedPathBeforeLock,
    );
    _closeSyncController.resetTracking();

    _setState(
      _currentState.copyWith(
        status: DatabaseStatus.locked,
        error: null,
        path: currentPath,
        name: currentName,
      ),
    );
    _ref.read(closeStoreSyncStatusProvider.notifier).clear();

    logInfo('Store locked successfully', tag: _logTag);
  }

  void resetState() {
    logInfo('Resetting state to idle', tag: _logTag);
    _setState(const DatabaseState(status: DatabaseStatus.idle));
  }

  Future<bool> unlockStore(String password) async {
    try {
      if (!_currentState.isLocked) {
        logWarning('Store is not locked, cannot unlock', tag: _logTag);
        return false;
      }

      logInfo('Unlocking store', tag: _logTag);

      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      final currentPath = _currentState.path;
      if (currentPath == null) {
        _setState(
          _currentState.copyWith(
            status: DatabaseStatus.error,
            error: DatabaseError.notInitialized(
              message: 'Путь к хранилищу не найден',
              timestamp: DateTime.now(),
            ),
          ),
        );
        return false;
      }

      await _manager.closeStore();

      final result = await _manager.openStore(
        OpenStoreDto(path: currentPath, password: password),
      );

      return result.fold(
        (storeInfo) {
          _setState(
            _currentState.copyWith(
              status: DatabaseStatus.open,
              modifiedAt: storeInfo.modifiedAt,
            ),
          );
          _closeSyncController.startTracking(
            initialModifiedAt: storeInfo.modifiedAt,
          );

          logInfo('Store unlocked successfully', tag: _logTag);
          unawaited(_runStartupCleanup());
          return true;
        },
        (error) {
          _setState(
            _currentState.copyWith(status: DatabaseStatus.locked, error: error),
          );

          logError('Failed to unlock store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (error, stackTrace) {
      logError(
        'Unexpected error unlocking store: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setState(
        _currentState.copyWith(
          status: DatabaseStatus.locked,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при разблокировке: $error',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> updateStore(UpdateStoreDto dto) async {
    try {
      if (!_currentState.isOpen) {
        logWarning('Store is not open, cannot update', tag: _logTag);
        return false;
      }

      logInfo('Updating store metadata', tag: _logTag);

      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      final result = await _manager.updateStore(dto);

      return result.fold(
        (storeInfo) {
          _setState(
            _currentState.copyWith(
              name: storeInfo.name,
              status: DatabaseStatus.open,
              modifiedAt: storeInfo.modifiedAt,
            ),
          );

          logInfo('Store updated successfully', tag: _logTag);
          return true;
        },
        (error) {
          _setState(
            _currentState.copyWith(status: DatabaseStatus.open, error: error),
          );

          logError('Failed to update store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (error, stackTrace) {
      logError(
        'Unexpected error updating store: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setErrorState(
        _currentState.copyWith(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при обновлении хранилища: $error',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> deleteStore(String path, {bool deleteFromDisk = true}) async {
    final deletedCurrentStore =
        _manager.currentStorePath == path && _manager.isStoreOpen;
    final success = await _storageController.deleteStore(
      ref: ref,
      manager: _manager,
      maintenanceService: _maintenanceService,
      session: _sessionBridge,
      path: path,
      deleteFromDisk: deleteFromDisk,
      logTag: _logTag,
    );

    if (success && deletedCurrentStore) {
      _closeSyncController.resetTracking();
    }
    return success;
  }

  Future<bool> deleteStoreFromDisk(String path) async {
    final deletedCurrentStore =
        _manager.currentStorePath == path && _manager.isStoreOpen;
    final success = await _storageController.deleteStoreFromDisk(
      ref: ref,
      manager: _manager,
      maintenanceService: _maintenanceService,
      session: _sessionBridge,
      path: path,
      logTag: _logTag,
    );

    if (success && deletedCurrentStore) {
      _closeSyncController.resetTracking();
    }
    return success;
  }

  Future<String?> getAttachmentsPath() {
    return _storageController.getAttachmentsPath(
      state: _currentState,
      manager: _manager,
      maintenanceService: _maintenanceService,
      logTag: _logTag,
    );
  }

  Future<String?> getDecryptedAttachmentsPath() {
    return _storageController.getDecryptedAttachmentsPath(
      state: _currentState,
      manager: _manager,
      maintenanceService: _maintenanceService,
      logTag: _logTag,
    );
  }

  Future<String?> createSubfolder(String folderName) {
    return _storageController.createSubfolder(
      state: _currentState,
      manager: _manager,
      maintenanceService: _maintenanceService,
      folderName: folderName,
      logTag: _logTag,
    );
  }

  void clearError() {
    _cancelErrorResetTimer();
    _setState(_currentState.copyWith(error: null));
  }

  DatabaseState _buildOpenFailureState(DatabaseError error) {
    if (_manager.isStoreOpen) {
      return _currentState.copyWith(status: DatabaseStatus.open, error: error);
    }

    return DatabaseState(status: DatabaseStatus.error, error: error);
  }

  Future<void> _runStartupCleanup() {
    return _storageController.runStartupCleanup(
      manager: _manager,
      maintenanceService: _maintenanceService,
      logTag: _logTag,
    );
  }

  Future<void> _tryUploadSnapshotBeforeClose({
    FutureOr<void> Function()? onCloseFlowRequired,
  }) {
    return _closeSyncController.tryUploadSnapshotBeforeClose(
      manager: _manager,
      logTag: _logTag,
      onCloseFlowRequired: onCloseFlowRequired,
    );
  }

  DatabaseError _buildCloseSyncFailure(
    Object error, {
    required StackTrace stackTrace,
  }) {
    return _closeSyncController.buildCloseSyncFailure(
      error,
      stackTrace: stackTrace,
    );
  }

  String _formatCloseSyncFailureMessage(Object error) {
    return _closeSyncController.formatCloseSyncFailureMessage(error);
  }

  Future<bool> _shouldAllowCloseWithoutSyncFailure(Object error) {
    return _closeSyncController.shouldAllowCloseWithoutSyncFailure(error);
  }

  Future<bool> _promptCloseStoreUploadDecision(
    StoreSyncStatus status, {
    FutureOr<void> Function()? onCloseFlowRequired,
  }) {
    return _closeSyncController.promptCloseStoreUploadDecision(
      status,
      logTag: _logTag,
      onCloseFlowRequired: onCloseFlowRequired,
    );
  }

  void resolveCloseStoreUploadDecision(bool shouldUpload) {
    _closeSyncController.resolveCloseStoreUploadDecision(shouldUpload);
  }

  void markSnapshotUploadOnCloseRequired() {
    _closeSyncController.markSnapshotUploadOnCloseRequired();
  }

  void syncPendingSnapshotUploadPrompt({
    required String? storeUuid,
    required bool hasBinding,
    required StoreVersionCompareResult? compareResult,
  }) {
    _closeSyncController.syncPendingSnapshotUploadPrompt(
      currentState: _currentState,
      currentStorePath: _manager.currentStorePath,
      storeUuid: storeUuid,
      hasBinding: hasBinding,
      compareResult: compareResult,
    );
  }

  MainStoreManager? get currentMainStoreManager => _manager;

  MainStore get currentDatabase {
    final db = _manager.currentStore;
    if (db == null) {
      logError(
        'Попытка доступа к базе данных, когда она не открыта',
        tag: 'DatabaseAsyncNotifier',
        data: <String, dynamic>{'state': state.toString()},
      );
      throw DatabaseError.unknown(
        message: 'Database must be opened before accessing it',
        stackTrace: StackTrace.current,
      );
    }
    return db;
  }
}
