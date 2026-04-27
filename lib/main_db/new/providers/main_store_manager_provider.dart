import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/index.dart' hide Session;
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/new/models/db_state.dart';
import 'package:hoplixi/main_db/new/models/session.dart';
import 'package:hoplixi/main_db/new/providers/main_store_close_sync_provider.dart';
import 'package:result_dart/result_dart.dart';
import 'package:riverpod/riverpod.dart';

import '../main_store_manager.dart';
import 'close_sync_tracking_provider.dart';
import 'db_history_provider.dart';

final mainStoreManagerProvider = FutureProvider<MainStoreManager>((ref) async {
  final dbHistoryService = await ref.watch(dbHistoryProvider.future);

  return MainStoreManager(dbHistoryService: dbHistoryService);
});

// Главный провайдер для управления состоянием базы данных и текущей сессией. Предоставляет методы для создания, открытия, закрытия и обновления хранилища, а также для получения текущего состояния базы данных и сессии. Состояние базы данных включает информацию о пути к хранилищу, информации о хранилище, статусе базы данных и возможных ошибках.
final mainStoreManagerStateProvider =
    AsyncNotifierProvider<MainStoreManagerNotifier, DatabaseState>(
      MainStoreManagerNotifier.new,
    );

class MainStoreManagerNotifier extends AsyncNotifier<DatabaseState> {
  static const String _logTag = 'MainStoreManagerNotifier';

  late MainStoreManager _manager;

  DatabaseState get _currentState =>
      state.value ?? const DatabaseState(status: DatabaseStatus.closed);

  MainStoreManager get currentManager => _manager;
  MainStore? get currentStore => _manager.currentStore;
  Session? get currentSession => _manager.currentSession;

  @override
  Future<DatabaseState> build() async {
    final manager = await ref.watch(mainStoreManagerProvider.future);
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
          _setOpenedSession(session, forceUpload: true);
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
          _setOpenedSession(session, forceUpload: allowMigration);
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

      final storePath = _manager.currentStorePath;
      if (storePath == null || storePath.isEmpty) {
        final error = _notInitializedError(
          'Путь открытого хранилища недоступен',
        );
        _setState(
          stateBeforeClose.copyWith(status: DatabaseStatus.open, error: error),
        );
        logWarning('Current store path is unavailable', tag: _logTag);
        return false;
      }

      final storeInfoResult = await _manager.getStoreInfo();
      if (storeInfoResult.isError()) {
        final error = storeInfoResult.exceptionOrNull()!;
        _setState(
          stateBeforeClose.copyWith(status: DatabaseStatus.open, error: error),
        );
        logError(
          'Failed to read store info before close: ${error.message}',
          tag: _logTag,
        );
        return false;
      }

      final storeInfo = storeInfoResult.getOrThrow();
      final shouldSyncAfterClose = ref
          .read(closeSyncTrackingProvider)
          .hasLogicalChanges(storeInfo.modifiedAt);

      _setState(
        stateBeforeClose.copyWith(status: DatabaseStatus.closing, error: null),
      );

      final result = await _manager.closeStore();
      if (result.isError()) {
        final error = result.exceptionOrNull()!;
        _setState(
          stateBeforeClose.copyWith(
            status: DatabaseStatus.open,
            error: error,
          ),
        );
        ref.read(mainStoreCloseSyncProvider.notifier).clearPublishedStatus();
        logError('Failed to close store: ${error.message}', tag: _logTag);
        return false;
      }

      _setState(const DatabaseState(status: DatabaseStatus.closed));
      logInfo('Store closed', tag: _logTag);

      if (shouldSyncAfterClose) {
        final closeSyncNotifier = ref.read(
          mainStoreCloseSyncProvider.notifier,
        );
        final syncResult = await closeSyncNotifier.uploadSnapshotAfterClose(
          storeInfo: storeInfo,
          currentStorePath: storePath,
        );

        if (syncResult.isError()) {
          final error = syncResult.exceptionOrNull()!;
          logError(
            'Snapshot sync after close failed: ${error.message}',
            tag: _logTag,
            data: <String, dynamic>{
              'storeUuid': storeInfo.id,
              'storePath': storePath,
              'errorType': error.runtimeType.toString(),
            },
          );
          _finalizeClosedStoreAfterCloseSync();
          return true;
        }

        _finalizeClosedStoreAfterCloseSync();
        return true;
      }

      _finalizeClosedStoreAfterCloseSync();
      return true;
    } catch (error, stackTrace) {
      ref.read(mainStoreCloseSyncProvider.notifier).clearPublishedStatus();
      _setUnexpectedErrorState(
        error,
        stackTrace,
        'Неожиданная ошибка при закрытии хранилища',
      );
      return false;
    }
  }

  Future<bool> updateStore(UpdateStoreDto dto) async {
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

      final result = await _manager.updateStore(session, dto);

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

  void _setState(DatabaseState newState) {
    state = AsyncData(newState);
  }

  void _finalizeClosedStoreAfterCloseSync() {
    _setState(const DatabaseState(status: DatabaseStatus.idle));
    ref.read(closeSyncTrackingProvider.notifier).reset();
    ref.read(mainStoreCloseSyncProvider.notifier).clearPublishedStatus();
  }

  void _setOpenedSession(Session session, {bool forceUpload = false}) {
    ref
        .read(closeSyncTrackingProvider.notifier)
        .start(session.info.modifiedAt, forceUpload: forceUpload);
    _setState(_stateFromSession(session));
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

  DatabaseState? _stateFromManager(MainStoreManager manager) {
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

  AppError _notInitializedError(String message) {
    return AppError.mainDatabase(
      code: MainDatabaseErrorCode.notInitialized,
      message: message,
      timestamp: DateTime.now(),
    );
  }
}
