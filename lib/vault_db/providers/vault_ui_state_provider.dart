import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/logger.dart' hide Session;
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/close_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_cloud_lock_provider.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/models/db_state.dart';
import 'package:hoplixi/vault_db/models/session.dart';
import 'service_providers.dart';
import 'package:hoplixi/vault_db/services/main_store_manager.dart';
import 'package:result_dart/result_dart.dart';

import '../../../features/cloud_sync/snapshot_sync/providers/close_sync_tracking_provider.dart';

/// Внутренний provider фасада vault database.
///
/// Публичным источником состояния остаётся [vaultDBManagerStateProvider].
final _vaultDBManagerProvider = FutureProvider<VaultDBManager>((ref) async {
  final dbHistory = await ref.watch(dbHistoryProvider.future);
  final manager = VaultDBManagerFactory(dbHistoryService: dbHistory).create();
  return manager;
});

/// Главный провайдер для управления UI состоянием базы данных.
final vaultDBManagerStateProvider =
    AsyncNotifierProvider<VaultDBManagerNotifier, DatabaseState>(
      VaultDBManagerNotifier.new,
    );

final dataUpdateStreamProvider = Provider<Stream<void>>((ref) {
  final state = ref.watch(vaultDBManagerStateProvider);

  return state.maybeWhen(
    data: (dbState) {
      if (!dbState.isOpen) {
        return const Stream.empty();
      }

      final store = ref
          .read(vaultDBManagerStateProvider.notifier)
          .requireDatabase;
      return store.watchVaultEventsHistoryUpdates();
    },
    orElse: () => const Stream.empty(),
  );
});

/// Тонкий презентационный нотифайер, управляющий DatabaseState.
/// Все сложные операции делегируются в VaultDBFacade.
class VaultDBManagerNotifier extends AsyncNotifier<DatabaseState> {
  static const String _logTag = 'VaultDBManagerNotifier';

  late VaultDBManager _manager;

  DatabaseState get _currentState =>
      state.value ?? const DatabaseState(status: DatabaseStatus.closed);

  AsyncResultDart<StoreInfoDto, AppError> get storeInfo {
    final session = _manager.currentSession;
    if (session == null) {
      return AsyncResultDart.error(
        AppError.mainDatabase(
          code: MainDatabaseErrorCode.notInitialized,
          message: 'База данных не открыта',
          timestamp: DateTime.now(),
        ),
      );
    }
    return _manager.getStoreInfo();
  }

  String? get currentStorePath => _manager.currentStorePath;

  VaultDB get requireDatabase {
    final api = _manager.currentApi;
    if (api == null) {
      throw AppError.mainDatabase(
        code: MainDatabaseErrorCode.notInitialized,
        message: 'База данных не открыта',
        timestamp: DateTime.now(),
      );
    }
    return api.db;
  }

  Session get currentSession {
    final session = _manager.currentSession;
    if (session == null) {
      throw AppError.mainDatabase(
        code: MainDatabaseErrorCode.notInitialized,
        message: 'Сессия не инициализирована',
        timestamp: DateTime.now(),
      );
    }
    return session;
  }

  @override
  Future<DatabaseState> build() async {
    final manager = await ref.watch(_vaultDBManagerProvider.future);
    _manager = manager;

    return _stateFromManager(manager) ??
        const DatabaseState(status: DatabaseStatus.idle);
  }

  Future<bool> createStore(CreateStoreDto dto, {String? masterPassword}) async {
    try {
      logInfo('Creating store', tag: _logTag, data: {'name': dto.name});
      _setState(
        const DatabaseState(
          status: DatabaseStatus.loading,
        ).copyWith(path: dto.path),
      );

      final result = await _manager.createStore(
        dto,
        masterPassword ?? dto.password,
      );

      return result.fold(
        (session) {
          _setOpenedSession(session, _currentState, forceUpload: true);
          logInfo('Store created', tag: _logTag, data: {'id': session.info.id});
          return true;
        },
        (error) {
          _setErrorState(error);
          logError('Failed to create store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (error, stackTrace) {
      _setUnexpectedErrorState(
        error,
        stackTrace,
        'Неожиданная ошибка при создании хранилища',
      );
      return false;
    }
  }

  Future<bool> openStore(OpenStoreDto dto, {String? masterPassword}) async {
    return _openStore(dto, masterPassword: masterPassword);
  }

  Future<bool> openStoreWithMigration(
    OpenStoreDto dto, {
    String? masterPassword,
  }) async {
    return _openStore(
      dto,
      masterPassword: masterPassword,
      allowMigration: true,
    );
  }

  Future<bool> _openStore(
    OpenStoreDto dto, {
    String? masterPassword,
    bool allowMigration = false,
  }) async {
    try {
      logInfo('Opening store', tag: _logTag, data: {'path': dto.path});
      _setState(DatabaseState(path: dto.path, status: DatabaseStatus.opening));

      final result = await _manager.openStore(
        dto,
        masterPassword ?? dto.password,
        allowMigration: allowMigration,
      );

      return result.fold(
        (session) {
          _setOpenedSession(
            session,
            _currentState,
            forceUpload: allowMigration,
          );
          logInfo('Store opened', tag: _logTag, data: {'id': session.info.id});
          return true;
        },
        (error) {
          _setErrorState(error);
          logError('Failed to open store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (error, stackTrace) {
      _setUnexpectedErrorState(
        error,
        stackTrace,
        'Неожиданная ошибка при открытии хранилища',
      );
      return false;
    }
  }

  Future<bool> closeStore() async {
    try {
      if (_manager.currentSession == null || !_currentState.isOpen) {
        final error = _notInitializedError('Хранилище не открыто');
        _setErrorState(error);
        logWarning('Store is not open, cannot close', tag: _logTag);
        return false;
      }

      final stateBeforeClose = _currentState;
      logInfo('Closing store', tag: _logTag);

      _prepareCloseSync(stateBeforeClose);

      _setState(
        stateBeforeClose.copyWith(status: DatabaseStatus.closing, error: null),
      );

      final result = await _manager.closeStore();
      if (result.isError()) {
        final error = result.exceptionOrNull()!;
        _setState(
          stateBeforeClose.copyWith(status: DatabaseStatus.open, error: error),
        );
        logError('Failed to close store: ${error.message}', tag: _logTag);
        return false;
      }

      _setState(const DatabaseState(status: DatabaseStatus.closed));
      _runCloseSyncAfterClose(stateBeforeClose);
      logInfo('Store closed', tag: _logTag);
      return true;
    } catch (error, stackTrace) {
      _setUnexpectedErrorState(
        error,
        stackTrace,
        'Неожиданная ошибка при закрытии хранилища',
      );
      return false;
    }
  }

  Future<void> lockStore({bool skipSnapshotSync = false}) async {
    try {
      if (_manager.currentSession == null || !_currentState.isOpen) {
        logWarning('Store is not open, cannot lock', tag: _logTag);
        return;
      }

      final stateBeforeLock = _currentState;
      logInfo('Locking store', tag: _logTag);

      final storePath = _manager.currentStorePath;
      if (storePath == null || storePath.isEmpty) {
        final error = _notInitializedError(
          'Путь открытого хранилища недоступен',
        );
        _setState(
          stateBeforeLock.copyWith(status: DatabaseStatus.open, error: error),
        );
        logWarning('Current store path is unavailable', tag: _logTag);
        return;
      }

      final storeInfoResult = await _manager.getStoreInfo();
      if (storeInfoResult.isError()) {
        final error = storeInfoResult.exceptionOrNull()!;
        _setState(
          stateBeforeLock.copyWith(status: DatabaseStatus.open, error: error),
        );
        logError(
          'Failed to read store info before lock: ${error.message}',
          tag: _logTag,
        );
        return;
      }

      final storeInfo = storeInfoResult.getOrThrow();
      if (!skipSnapshotSync) {
        _prepareCloseSync(
          stateBeforeLock.copyWith(path: storePath, info: storeInfo),
        );
      }

      _setState(
        stateBeforeLock.copyWith(status: DatabaseStatus.closing, error: null),
      );

      final result = await _manager.closeStore();
      if (result.isError()) {
        final error = result.exceptionOrNull()!;
        _setState(
          stateBeforeLock.copyWith(status: DatabaseStatus.open, error: error),
        );
        logError(
          'Failed to close store during lock: ${error.message}',
          tag: _logTag,
        );
        return;
      }

      _setState(
        stateBeforeLock.copyWith(
          status: DatabaseStatus.locked,
          error: null,
          path: storePath,
          info: storeInfo,
          modifiedAt: storeInfo.modifiedAt,
        ),
      );
      _runCloseSyncAfterClose(
        stateBeforeLock.copyWith(path: storePath, info: storeInfo),
      );
      logInfo('Store locked successfully', tag: _logTag);
    } catch (error, stackTrace) {
      _setUnexpectedErrorState(
        error,
        stackTrace,
        'Неожиданная ошибка при блокировке хранилища',
      );
    }
  }

  Future<bool> unlockStore(
    String password, {
    String? keyFileId,
    Uint8List? keyFileSecret,
  }) async {
    try {
      if (!_currentState.isLocked) {
        logWarning('Store is not locked, cannot unlock', tag: _logTag);
        return false;
      }

      final lockedState = _currentState;
      final storePath = lockedState.path;
      if (storePath == null || storePath.isEmpty) {
        final error = _notInitializedError('Путь к хранилищу не найден');
        _setState(
          lockedState.copyWith(status: DatabaseStatus.error, error: error),
        );
        return false;
      }

      logInfo('Unlocking store', tag: _logTag, data: {'path': storePath});
      _setState(
        lockedState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      final result = await _manager.openStore(
        OpenStoreDto(
          path: storePath,
          password: password,
          keyFileId: keyFileId,
          keyFileSecret: keyFileSecret,
        ),
        password,
      );

      return result.fold(
        (session) {
          _setOpenedSession(session, lockedState);
          logInfo('Store unlocked successfully', tag: _logTag);
          return true;
        },
        (error) {
          _setState(
            lockedState.copyWith(status: DatabaseStatus.locked, error: error),
          );
          logError('Failed to unlock store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (error, stackTrace) {
      _setState(
        _currentState.copyWith(
          status: DatabaseStatus.locked,
          error: AppError.mainDatabase(
            code: MainDatabaseErrorCode.unknown,
            message: 'Неожиданная ошибка при разблокировке хранилища',
            cause: error,
            stackTrace: stackTrace,
            timestamp: DateTime.now(),
          ),
        ),
      );
      logError(
        'Unexpected error unlocking store: $error',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> deleteStore(String path, {bool deleteFromDisk = true}) async {
    return _deleteStore(path, deleteFromDisk: deleteFromDisk);
  }

  Future<bool> deleteStoreFromDisk(String path) async {
    return _deleteStore(path, deleteFromDisk: true);
  }

  Future<bool> _deleteStore(String path, {required bool deleteFromDisk}) async {
    final previousState = _currentState;
    final deletingTrackedStore = _isCurrentOrLockedStorePath(path);

    try {
      logInfo('Deleting store', tag: _logTag, data: {'path': path});
      _setState(
        previousState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      final result = await _manager.deleteStore(
        path,
        deleteFromDisk: deleteFromDisk,
      );

      return result.fold(
        (_) {
          final deletedActiveStore =
              previousState.isOpen && !_manager.isStoreOpen;
          if (deletingTrackedStore || deletedActiveStore) {
            _finalizeDeletedCurrentStore();
          } else {
            _setState(
              _stateFromManager(_manager) ??
                  previousState.copyWith(error: null),
            );
          }

          logInfo('Store deleted successfully', tag: _logTag);
          return true;
        },
        (error) {
          _setState(previousState.copyWith(error: error));
          logError('Failed to delete store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (error, stackTrace) {
      _setUnexpectedErrorState(
        error,
        stackTrace,
        'Неожиданная ошибка при удалении хранилища',
      );
      return false;
    }
  }

  Future<bool> updateStore(PatchStoreDto dto) async {
    try {
      final session = _manager.currentSession;
      if (session == null || !_currentState.isOpen) {
        final error = _notInitializedError('Хранилище не открыто');
        _setErrorState(error);
        logWarning('Store is not open, cannot update', tag: _logTag);
        return false;
      }

      final previousState = _currentState;
      logInfo('Updating store metadata', tag: _logTag);
      _setState(previousState.copyWith(status: DatabaseStatus.loading));

      final result = await _manager.updateStore(dto);

      return result.fold(
        (storeInfo) {
          _setState(
            previousState.copyWith(
              info: storeInfo,
              status: DatabaseStatus.open,
              error: null,
              modifiedAt: storeInfo.modifiedAt,
            ),
          );
          logInfo('Store metadata updated', tag: _logTag);
          return true;
        },
        (error) {
          _setState(
            previousState.copyWith(status: DatabaseStatus.open, error: error),
          );
          logError('Failed to update store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (error, stackTrace) {
      _setUnexpectedErrorState(
        error,
        stackTrace,
        'Неожиданная ошибка при обновлении хранилища',
      );
      return false;
    }
  }

  void clearError() {
    _setState(_currentState.copyWith(error: null));
  }

  void resetState() {
    ref.read(closeSyncTrackingProvider.notifier).reset();
    _setState(const DatabaseState(status: DatabaseStatus.closed));
  }

  void setOpenFailure(AppError error) {
    _setState(DatabaseState(status: DatabaseStatus.error, error: error));
  }

  void markOpeningStarted({String? path, String? name}) {
    _setState(
      _currentState.copyWith(
        path: path ?? _currentState.path,
        status: DatabaseStatus.opening,
        error: null,
      ),
    );
  }

  Future<String?> getAttachmentsPath() async {
    return _manager.getAttachmentsPath();
  }

  Future<String?> getDecryptedAttachmentsPath() async {
    return _manager.getDecryptedAttachmentsPath();
  }

  Future<String?> createSubfolder(String folderName) async {
    final result = await _manager.createSubfolder(folderName);
    return result.fold((path) => path, (error) {
      _setState(_currentState.copyWith(error: error));
      logError(
        'Failed to create store subfolder: ${error.message}',
        tag: _logTag,
      );
      return null;
    });
  }

  void resolveCloseStoreUploadDecision(bool shouldUpload) {
    ref
        .read(vaultDBCloseSyncProvider.notifier)
        .resolveCloseStoreUploadDecision(shouldUpload);
  }

  void markSnapshotUploadOnCloseRequired() {
    ref
        .read(vaultDBCloseSyncProvider.notifier)
        .markSnapshotUploadOnCloseRequired(
          storeUuid: _currentState.info?.id,
          storePath: _manager.currentStorePath ?? _currentState.path,
        );
  }

  void syncPendingSnapshotUploadPrompt({
    required String? storeUuid,
    required bool hasBinding,
    required StoreVersionCompareResult? compareResult,
  }) {
    ref
        .read(vaultDBCloseSyncProvider.notifier)
        .syncPendingSnapshotUploadPrompt(
          isStoreOpen: _currentState.isOpen,
          currentStorePath: _manager.currentStorePath,
          storeUuid: storeUuid,
          statusStorePath: _manager.currentStorePath,
          hasBinding: hasBinding,
          compareResult: compareResult,
        );
  }

  void _setState(DatabaseState newState) {
    state = AsyncData(newState);
  }

  void _prepareCloseSync(DatabaseState openState) {
    final storeInfo = openState.info;
    final storePath = openState.path;
    if (storeInfo == null || storePath == null || storePath.isEmpty) {
      return;
    }

    logInfo('Preparing close sync', tag: _logTag);
    ref
        .read(vaultDBCloseSyncProvider.notifier)
        .markCurrentStoreUploadRequiredIfLocalNewer(
          storeUuid: storeInfo.id,
          storePath: storePath,
        );
  }

  void _runCloseSyncAfterClose(DatabaseState closingState) {
    final storeInfo = closingState.info;
    final storePath = closingState.path;
    if (storeInfo == null || storePath == null || storePath.isEmpty) {
      return;
    }

    unawaited(
      _finalizeCloseSyncAfterClose(storeInfo: storeInfo, storePath: storePath),
    );
  }

  Future<void> _finalizeCloseSyncAfterClose({
    required StoreInfoDto storeInfo,
    required String storePath,
  }) async {
    final shouldSync = ref
        .read(closeSyncTrackingProvider)
        .hasLogicalChanges(storeInfo.modifiedAt);

    if (shouldSync) {
      logInfo('Uploading database snapshot after close...', tag: _logTag);
      final syncResult = await ref
          .read(vaultDBCloseSyncProvider.notifier)
          .uploadSnapshotAfterClose(
            storeInfo: storeInfo,
            currentStorePath: storePath,
          );

      if (syncResult.isError()) {
        final error = syncResult.exceptionOrNull()!;
        logError(
          'Snapshot sync after close failed: ${error.message}',
          tag: _logTag,
        );
      }
    }

    final releaseResult = await ref
        .read(currentStoreCloudLockProvider.notifier)
        .releaseCurrentLock();
    if (releaseResult.isError()) {
      logError(
        'Failed to release cloud store lock: ${releaseResult.exceptionOrNull()!.message}',
        tag: _logTag,
      );
    }

    ref.read(closeSyncTrackingProvider.notifier).closeSession();
    ref.read(vaultDBCloseSyncProvider.notifier).clearPublishedStatus();
    logInfo('Close sync process and lock release finalized', tag: _logTag);
  }

  void _finalizeDeletedCurrentStore() {
    ref.read(closeSyncTrackingProvider.notifier).reset();
    ref.read(vaultDBCloseSyncProvider.notifier).reset();
    _setState(const DatabaseState(status: DatabaseStatus.idle));
  }

  void _setOpenedSession(
    Session session,
    DatabaseState state, {
    bool forceUpload = false,
  }) {
    ref
        .read(closeSyncTrackingProvider.notifier)
        .start(
          session.info.modifiedAt,
          storeUuid: session.info.id,
          storePath: state.path,
          forceUpload: forceUpload,
        );
    _setState(_stateFromSession(session));
    _scheduleStoreCleanup(session);
  }

  void _scheduleStoreCleanup(Session session) {
    scheduleMicrotask(() async {
      try {
        await session.api.store.performCleanup(
          storePath: session.storeDirectoryPath,
          ignoreInterval: false,
        );
        logInfo(
          'Background store cleanup completed successfully',
          tag: _logTag,
        );
      } catch (error, stackTrace) {
        logWarning(
          'Failed to perform store cleanup in background',
          tag: _logTag,
          data: {
            'storeId': session.info.id,
            'storePath': session.storeDirectoryPath,
            'error': error.toString(),
            'stackTrace': stackTrace.toString(),
          },
        );
      }
    });
  }

  void _setErrorState(AppError error) {
    _setState(
      _currentState.copyWith(status: DatabaseStatus.error, error: error),
    );
  }

  void _setUnexpectedErrorState(
    Object error,
    StackTrace stackTrace,
    String message,
  ) {
    logError('$message: $error', tag: _logTag, stackTrace: stackTrace);
    _setErrorState(
      AppError.mainDatabase(
        code: MainDatabaseErrorCode.unknown,
        message: message,
        cause: error,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
      ),
    );
  }

  DatabaseState? _stateFromManager(VaultDBManager manager) {
    final session = manager.currentSession;
    if (session == null || !manager.isStoreOpen) {
      return null;
    }

    return _stateFromSession(session);
  }

  DatabaseState _stateFromSession(Session session) {
    return DatabaseState(
      path: session.storeDirectoryPath,
      info: session.info,
      status: DatabaseStatus.open,
      modifiedAt: session.info.modifiedAt,
    );
  }

  bool _isCurrentOrLockedStorePath(String path) {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) {
      return false;
    }

    return _manager.currentStorePath == normalizedPath ||
        _currentState.path == normalizedPath;
  }

  AppError _notInitializedError(String message) {
    return AppError.mainDatabase(
      code: MainDatabaseErrorCode.notInitialized,
      message: message,
      timestamp: DateTime.now(),
    );
  }
}
