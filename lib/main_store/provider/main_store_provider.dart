import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/di_init.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/main_store_manager.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:hoplixi/main_store/models/db_state.dart';
import 'package:hoplixi/main_store/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_store/provider/db_history_provider.dart';
import 'package:hoplixi/main_store/services/db_key_derivation_service.dart';
import 'package:hoplixi/main_store/services/main_store_backup_service.dart';
import 'package:hoplixi/main_store/services/main_store_maintenance_service.dart';

enum BackupScope { databaseOnly, encryptedFilesOnly, full }

class BackupResult {
  final String backupPath;
  final BackupScope scope;
  final DateTime createdAt;
  final bool periodic;

  const BackupResult({
    required this.backupPath,
    required this.scope,
    required this.createdAt,
    required this.periodic,
  });
}

final _mainStoreManagerProvider = FutureProvider<MainStoreManager>((ref) async {
  final dbHistoryService = await ref.read(dbHistoryProvider.future);
  final keyService = DbKeyDerivationService(getIt<FlutterSecureStorage>());
  final manager = MainStoreManager(dbHistoryService, keyService);

  // Cleanup on dispose
  ref.onDispose(() {
    logInfo(
      'Освобождение ресурсов databaseManagerProvider',
      tag: 'DatabaseProviders',
    );
    // manager.dispose();
  });

  return manager;
});

/// Провайдер для MainStoreManager (AsyncNotifier версия)
final mainStoreProvider =
    AsyncNotifierProvider<MainStoreAsyncNotifier, DatabaseState>(
      MainStoreAsyncNotifier.new,
    );

/// state provider
final mainStoreStateProvider = FutureProvider<DatabaseState>((ref) async {
  return ref.watch(mainStoreProvider.future);
});

/// Провайдер для получения MainStoreManager по готовности
///
/// Отслеживает состояние БД и предоставляет менеджер только когда хранилище открыто.
/// Возвращает null если хранилище не открыто или находится в процессе открытия/закрытия.
final mainStoreManagerProvider = FutureProvider<MainStoreManager?>((ref) async {
  final asyncState = await ref.watch(mainStoreProvider.future);

  return asyncState.isOpen
      ? ref.read(mainStoreProvider.notifier).currentMainStoreManager
      : null;
});

/// Провайдер для потока обновлений данных
///
/// Предоставляет Stream<void> для отслеживания изменений в базе данных.
/// Доступен только когда хранилище открыто.
final dataUpdateStreamProvider = Provider<Stream<void>>((ref) {
  final managerAsync = ref.watch(mainStoreManagerProvider);

  return managerAsync.maybeWhen(
    data: (manager) {
      if (manager != null && manager.currentStore != null) {
        // Drift watch() emits the current snapshot immediately on subscribe.
        // For "data changed" consumers we only need subsequent changes.
        return manager.currentStore!.watchDataChanged().skip(1);
      }
      return const Stream.empty();
    },
    orElse: () => const Stream.empty(),
  );
});

/// AsyncNotifier для управления состоянием хранилища MainStore
///
/// Предоставляет методы для:
/// - Создания нового хранилища
/// - Открытия существующего хранилища
/// - Закрытия хранилища
/// - Блокировки хранилища
/// - Обновления метаданных
/// - Удаления хранилища
class MainStoreAsyncNotifier extends AsyncNotifier<DatabaseState> {
  static const String _logTag = 'MainStoreAsyncNotifier';
  static const Duration _errorResetDelay = Duration(seconds: 10);

  late final MainStoreManager _manager;
  Timer? _errorResetTimer;
  Timer? _periodicBackupTimer;
  Duration? _periodicBackupInterval;
  BackupScope _periodicBackupScope = BackupScope.full;
  String? _periodicBackupOutputDirPath;
  int _periodicBackupMaxPerStore = 10;
  DateTime? _openedStoreModifiedAt;
  bool _forceSnapshotUploadOnClose = false;

  /// Completer для блокировки параллельных операций (защита от race condition)
  Completer<void>? _operationLock;
  final MainStoreBackupService _backupService = MainStoreBackupService();
  final MainStoreMaintenanceService _maintenanceService =
      MainStoreMaintenanceService();

  /// Получить текущее значение состояния или дефолтное
  DatabaseState get _currentState {
    return state.value ?? const DatabaseState(status: DatabaseStatus.idle);
  }

  /// Установить новое состояние
  void _setState(DatabaseState newState) {
    state = AsyncValue.data(newState);
  }

  /// Установить состояние ошибки с автоматическим сбросом до idle через 10 секунд
  void _setErrorState(DatabaseState errorState) {
    _cancelErrorResetTimer();
    _setState(errorState);
    _scheduleErrorReset();
  }

  /// Запланировать сброс состояния ошибки до idle
  void _scheduleErrorReset() {
    _errorResetTimer = Timer(_errorResetDelay, () {
      if (_currentState.hasError &&
          _currentState.status == DatabaseStatus.error) {
        logInfo('Автоматический сброс состояния ошибки до idle', tag: _logTag);
        _setState(const DatabaseState(status: DatabaseStatus.idle));
      }
    });
  }

  /// Отменить таймер сброса ошибки
  void _cancelErrorResetTimer() {
    _errorResetTimer?.cancel();
    _errorResetTimer = null;
  }

  /// Получить блокировку для операции (защита от race condition)
  ///
  /// Ожидает завершения предыдущей операции, если она выполняется
  Future<void> _acquireLock() async {
    // Ожидаем завершения предыдущей операции
    while (_operationLock != null) {
      logInfo('Ожидание завершения предыдущей операции...', tag: _logTag);
      await _operationLock!.future;
    }
    // Создаём новую блокировку
    _operationLock = Completer<void>();
  }

  /// Освободить блокировку операции
  void _releaseLock() {
    _operationLock?.complete();
    _operationLock = null;
  }

  @override
  Future<DatabaseState> build() async {
    // Инициализация с idle состоянием

    logInfo('MainStoreAsyncNotifier initialized', tag: _logTag);
    _manager = await ref.read(_mainStoreManagerProvider.future);

    ref.onDispose(() {
      _periodicBackupTimer?.cancel();
      _periodicBackupTimer = null;
      _resetSnapshotCloseTracking();
    });

    return const DatabaseState(status: DatabaseStatus.idle);
  }

  Future<BackupResult?> createBackup({
    BackupScope scope = BackupScope.full,
    String? outputDirPath,
    bool periodic = false,
    int maxBackupsPerStore = 10,
  }) async {
    try {
      if (!_currentState.isOpen) {
        logWarning('Store is not open, cannot create backup', tag: _logTag);
        return null;
      }

      final storeDirPath = _currentState.path ?? _manager.currentStorePath;
      if (storeDirPath == null || storeDirPath.isEmpty) {
        logError('Store path is null, backup aborted', tag: _logTag);
        return null;
      }

      final attachmentsPath =
          scope == BackupScope.encryptedFilesOnly || scope == BackupScope.full
          ? await getAttachmentsPath()
          : null;

      final backupData = await _backupService.createBackup(
        storeDirPath: storeDirPath,
        storeName: _currentState.name ?? 'store',
        includeDatabase:
            scope == BackupScope.databaseOnly || scope == BackupScope.full,
        includeEncryptedFiles:
            scope == BackupScope.encryptedFilesOnly ||
            scope == BackupScope.full,
        attachmentsPath: attachmentsPath,
        outputDirPath: outputDirPath,
        periodic: periodic,
        maxBackupsPerStore: maxBackupsPerStore,
      );

      logInfo(
        'Backup created successfully: ${backupData.backupPath} (scope: ${scope.name})',
        tag: _logTag,
      );

      return BackupResult(
        backupPath: backupData.backupPath,
        scope: scope,
        createdAt: backupData.createdAt,
        periodic: periodic,
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to create backup: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return null;
    }
  }

  void startPeriodicBackup({
    required Duration interval,
    BackupScope scope = BackupScope.full,
    String? outputDirPath,
    bool runImmediately = false,
    int maxBackupsPerStore = 10,
  }) {
    if (interval.inSeconds <= 0) {
      logWarning('Invalid backup interval: $interval', tag: _logTag);
      return;
    }

    stopPeriodicBackup();

    _periodicBackupInterval = interval;
    _periodicBackupScope = scope;
    _periodicBackupOutputDirPath = outputDirPath;
    _periodicBackupMaxPerStore = maxBackupsPerStore <= 0
        ? 1
        : maxBackupsPerStore;

    _periodicBackupTimer = Timer.periodic(interval, (_) {
      unawaited(_runPeriodicBackupTick());
    });

    if (runImmediately) {
      unawaited(_runPeriodicBackupTick());
    }

    logInfo(
      'Periodic backup started (interval: $interval, scope: ${scope.name})',
      tag: _logTag,
    );
  }

  Future<void> _runPeriodicBackupTick() async {
    if (!_currentState.isOpen) {
      return;
    }

    await createBackup(
      scope: _periodicBackupScope,
      outputDirPath: _periodicBackupOutputDirPath,
      periodic: true,
      maxBackupsPerStore: _periodicBackupMaxPerStore,
    );
  }

  void stopPeriodicBackup() {
    _periodicBackupTimer?.cancel();
    _periodicBackupTimer = null;
    _periodicBackupInterval = null;
    _periodicBackupOutputDirPath = null;

    logInfo('Periodic backup stopped', tag: _logTag);
  }

  bool get isPeriodicBackupActive => _periodicBackupTimer != null;

  /// Создать новое хранилище
  ///
  /// [dto] - данные для создания (имя, описание, пароль)
  /// Возвращает true если успешно, false если ошибка
  Future<bool> createStore(CreateStoreDto dto) async {
    // Защита от race condition
    await _acquireLock();

    try {
      logInfo('Creating store: ${dto.name}', tag: _logTag);

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      // Вызываем создание хранилища
      final result = await _manager.createStore(dto);

      return result.fold(
        (storeInfo) {
          // Успех - обновляем состояние
          _setState(
            DatabaseState(
              path: _manager.currentStorePath,
              name: storeInfo.name,
              status: DatabaseStatus.open,
              modifiedAt: storeInfo.modifiedAt,
            ),
          );
          _startSnapshotCloseTracking(
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
          // Ошибка - сохраняем в состоянии с автосбросом
          _setErrorState(
            DatabaseState(status: DatabaseStatus.error, error: error),
          );

          logError('Failed to create store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Unexpected error creating store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setErrorState(
        DatabaseState(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при создании хранилища: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    } finally {
      // Освобождаем блокировку в любом случае
      _releaseLock();
    }
  }

  /// Открыть существующее хранилище
  ///
  /// [dto] - данные для открытия (путь, пароль)
  /// Возвращает true если успешно, false если ошибка
  Future<bool> openStore(OpenStoreDto dto) async {
    // Защита от race condition
    await _acquireLock();

    try {
      logInfo('Opening store at: ${dto.path}', tag: _logTag);

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      // Вызываем открытие хранилища
      final result = await _manager.openStore(dto);

      return result.fold(
        (storeInfo) {
          // Успех - обновляем состояние
          _setState(
            DatabaseState(
              path: _manager.currentStorePath,
              name: storeInfo.name,
              status: DatabaseStatus.open,
              modifiedAt: storeInfo.modifiedAt,
            ),
          );
          _startSnapshotCloseTracking(initialModifiedAt: storeInfo.modifiedAt);

          logInfo('Store opened successfully: ${storeInfo.name}', tag: _logTag);
          unawaited(_runStartupCleanup());
          return true;
        },
        (error) {
          // Ошибка - сохраняем в состоянии с автосбросом
          _setErrorState(
            DatabaseState(status: DatabaseStatus.error, error: error),
          );

          logError('Failed to open store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Unexpected error opening store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setErrorState(
        DatabaseState(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при открытии хранилища: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    } finally {
      // Освобождаем блокировку в любом случае
      _releaseLock();
    }
  }

  /// Закрыть текущее хранилище
  ///
  /// Возвращает true если успешно, false если ошибка
  Future<bool> closeStore() async {
    // Защита от race condition
    await _acquireLock();
    DatabaseState? openStateBeforeClose;

    try {
      logInfo('Closing store', tag: _logTag);

      if (!_currentState.isOpen) {
        logWarning('Store is not open, cannot close', tag: _logTag);
        return false;
      }

      openStateBeforeClose = _currentState;
      final decryptedPathBeforeClose = await getDecryptedAttachmentsPath();

      await _tryUploadSnapshotBeforeClose(
        onSyncStart: () {
          _setState(
            openStateBeforeClose!.copyWith(
              status: DatabaseStatus.closingSync,
              error: null,
            ),
          );
        },
      );

      // Вызываем закрытие хранилища
      final result = await _manager.closeStore();

      final isClosed = result.fold((_) => true, (error) {
        // Ошибка - возвращаем пользователя в открытое состояние хранилища.
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
        return false;
      }

      await _maintenanceService.cleanupDecryptedAttachmentsDir(
        decryptedPathBeforeClose,
      );
      _resetSnapshotCloseTracking();

      // Успех - переводим в idle состояние
      _setState(const DatabaseState(status: DatabaseStatus.closed));
      _setState(const DatabaseState(status: DatabaseStatus.idle));

      logInfo('Store closed successfully', tag: _logTag);
      return true;
    } catch (e, stackTrace) {
      logError(
        'Unexpected error closing store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setState(
        (openStateBeforeClose ?? _currentState).copyWith(
          status: openStateBeforeClose != null
              ? DatabaseStatus.open
              : DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при закрытии хранилища: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    } finally {
      // Освобождаем блокировку в любом случае
      _releaseLock();
    }
  }

  /// Блокировать текущее хранилище
  ///
  /// Блокирует хранилище и закрывает соединение.
  /// Пользователь должен будет ввести пароль для разблокировки.
  Future<void> lockStore({bool skipSnapshotSync = false}) async {
    if (!_currentState.isOpen) {
      logWarning('Store is not open, cannot lock', tag: _logTag);
      return;
    }

    logInfo('Locking store', tag: _logTag);

    final currentPath = _currentState.path;
    final currentName = _currentState.name;
    final decryptedPathBeforeLock = await getDecryptedAttachmentsPath();

    if (!skipSnapshotSync) {
      await _tryUploadSnapshotBeforeClose();
    }

    // Закрываем соединение
    final closeResult = await _manager.closeStore();

    closeResult.fold((_) => null, (error) {
      logError(
        'Failed to close store during lock: ${error.message}',
        tag: _logTag,
      );
      return null;
    });

    await _maintenanceService.cleanupDecryptedAttachmentsDir(
      decryptedPathBeforeLock,
    );
    _resetSnapshotCloseTracking();

    _setState(
      _currentState.copyWith(
        status: DatabaseStatus.locked,
        error: null,
        path: currentPath,
        name: currentName,
      ),
    );

    logInfo('Store locked successfully', tag: _logTag);
  }

  /// Сбросить состояние (выход на главный экран)
  void resetState() {
    logInfo('Resetting state to idle', tag: _logTag);
    _setState(const DatabaseState(status: DatabaseStatus.idle));
  }

  /// Выполнить стартовую чистку
  Future<void> _runStartupCleanup() async {
    try {
      final store = _manager.currentStore;
      if (store == null) return;

      final storePath = _manager.currentStorePath;
      if (storePath == null || storePath.isEmpty) return;

      await _maintenanceService.runStartupCleanup(
        store: store,
        storePath: storePath,
      );
    } catch (e, s) {
      logError('Startup cleanup failed: $e', stackTrace: s, tag: _logTag);
    }
  }

  Future<void> _tryUploadSnapshotBeforeClose({
    FutureOr<void> Function()? onSyncStart,
  }) async {
    try {
      final storePath = _manager.currentStorePath;
      if (storePath == null || storePath.isEmpty || !_manager.isStoreOpen) {
        return;
      }
      final storeInfoResult = await _manager.getStoreInfo();
      final storeInfo = storeInfoResult.fold((info) => info, (error) {
        throw error;
      });
      final currentModifiedAt = storeInfo.modifiedAt.toUtc();
      final hasLogicalChanges =
          _forceSnapshotUploadOnClose ||
          _openedStoreModifiedAt == null ||
          !_openedStoreModifiedAt!.isAtSameMomentAs(currentModifiedAt);

      if (!hasLogicalChanges) {
        logDebug(
          'Skipping snapshot sync before close because StoreMeta.modifiedAt did not change during the current session.',
          tag: _logTag,
          data: <String, dynamic>{
            'storePath': storePath,
            'openedStoreModifiedAt': _openedStoreModifiedAt?.toIso8601String(),
            'currentStoreModifiedAt': currentModifiedAt.toIso8601String(),
          },
        );
        return;
      }

      final binding = await ref
          .read(storeSyncBindingServiceProvider)
          .getByStoreUuid(storeInfo.id);
      if (binding == null) {
        return;
      }

      await onSyncStart?.call();

      final token = await ref
          .read(authTokensProvider.notifier)
          .getTokenById(binding.tokenId);
      if (token == null) {
        logWarning(
          'Skipping snapshot sync before close because token binding is stale.',
          tag: _logTag,
          data: <String, dynamic>{
            'storeUuid': storeInfo.id,
            'tokenId': binding.tokenId,
          },
        );
        return;
      }

      final syncService = ref.read(snapshotSyncServiceProvider);
      final status = await syncService.loadStatus(
        storePath: storePath,
        storeInfo: storeInfo,
        binding: binding,
        token: token,
        persistLocalSnapshot: true,
        allowLocalRevisionBump: true,
      );

      switch (status.compareResult) {
        case StoreVersionCompareResult.remoteMissing:
        case StoreVersionCompareResult.localNewer:
          final result = await ref
              .read(currentStoreSyncProvider.notifier)
              .syncBeforeClose(
                status: status,
                storePath: storePath,
                storeInfo: storeInfo,
                binding: binding,
                token: token,
              );
          logInfo(
            'Snapshot sync before close completed.',
            tag: _logTag,
            data: <String, dynamic>{
              'storeUuid': storeInfo.id,
              'resultType': result.type.name,
            },
          );
          break;
        case StoreVersionCompareResult.same:
          logDebug(
            'Skipping snapshot upload before close because local and remote versions match.',
            tag: _logTag,
            data: <String, dynamic>{'storeUuid': storeInfo.id},
          );
          break;
        case StoreVersionCompareResult.remoteNewer:
        case StoreVersionCompareResult.conflict:
        case StoreVersionCompareResult.differentStore:
          logWarning(
            'Skipping snapshot upload before close because manual resolution is required.',
            tag: _logTag,
            data: <String, dynamic>{
              'storeUuid': storeInfo.id,
              'compareResult': status.compareResult.name,
            },
          );
          break;
      }
    } catch (e, stackTrace) {
      logError(
        'Snapshot sync before close failed: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }

  /// Разблокировать хранилище
  ///
  /// [password] - пароль для разблокировки
  /// Возвращает true если успешно, false если неверный пароль
  Future<bool> unlockStore(String password) async {
    try {
      if (!_currentState.isLocked) {
        logWarning('Store is not locked, cannot unlock', tag: _logTag);
        return false;
      }

      logInfo('Unlocking store', tag: _logTag);

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      // Проверяем пароль через повторное открытие
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

      // Закрываем текущее соединение
      await _manager.closeStore();

      // Пытаемся открыть заново с паролем
      final result = await _manager.openStore(
        OpenStoreDto(path: currentPath, password: password),
      );

      return result.fold(
        (storeInfo) {
          // Успех - разблокируем
          _setState(
            _currentState.copyWith(
              status: DatabaseStatus.open,
              modifiedAt: storeInfo.modifiedAt,
            ),
          );

          logInfo('Store unlocked successfully', tag: _logTag);
          unawaited(_runStartupCleanup());
          return true;
        },
        (error) {
          // Неверный пароль - остаемся заблокированными
          _setState(
            _currentState.copyWith(status: DatabaseStatus.locked, error: error),
          );

          logError('Failed to unlock store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Unexpected error unlocking store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setState(
        _currentState.copyWith(
          status: DatabaseStatus.locked,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при разблокировке: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    }
  }

  /// Обновить метаданные хранилища
  ///
  /// [dto] - данные для обновления (имя, описание, пароль)
  /// Возвращает true если успешно, false если ошибка
  Future<bool> updateStore(UpdateStoreDto dto) async {
    try {
      if (!_currentState.isOpen) {
        logWarning('Store is not open, cannot update', tag: _logTag);
        return false;
      }

      logInfo('Updating store metadata', tag: _logTag);

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      // Вызываем обновление хранилища
      final result = await _manager.updateStore(dto);

      return result.fold(
        (storeInfo) {
          // Успех - обновляем состояние
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
          // Ошибка - возвращаем открытое состояние с ошибкой
          _setState(
            _currentState.copyWith(status: DatabaseStatus.open, error: error),
          );

          logError('Failed to update store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Unexpected error updating store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setErrorState(
        _currentState.copyWith(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при обновлении хранилища: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    }
  }

  /// Удалить хранилище
  ///
  /// [path] - путь к хранилищу
  /// [deleteFromDisk] - удалить файлы с диска (по умолчанию true)
  /// Возвращает true если успешно, false если ошибка
  Future<bool> deleteStore(String path, {bool deleteFromDisk = true}) async {
    try {
      logInfo('Deleting store at: $path', tag: _logTag);

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      if (_manager.currentStorePath == path && _manager.isStoreOpen) {
        await _manager.closeStore();
      }

      final dbHistoryService = await ref.read(dbHistoryProvider.future);
      await dbHistoryService.deleteByPath(path);

      if (deleteFromDisk &&
          await _maintenanceService.storageDirectoryExists(path)) {
        await _maintenanceService.deleteStorageDirectory(path);
      }

      _setState(const DatabaseState(status: DatabaseStatus.idle));

      logInfo('Store deleted successfully', tag: _logTag);
      return true;
    } catch (e, stackTrace) {
      logError(
        'Unexpected error deleting store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setErrorState(
        DatabaseState(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при удалении хранилища: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    }
  }

  /// Удалить хранилище только с диска (запись в истории остается)
  ///
  /// [path] - путь к хранилищу
  /// Возвращает true если успешно, false если ошибка
  Future<bool> deleteStoreFromDisk(String path) async {
    try {
      logInfo('Deleting store from disk at: $path', tag: _logTag);

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      if (_manager.currentStorePath == path && _manager.isStoreOpen) {
        await _manager.closeStore();
      }

      if (!await _maintenanceService.storageDirectoryExists(path)) {
        _setErrorState(
          DatabaseState(
            status: DatabaseStatus.error,
            error: DatabaseError.recordNotFound(
              message: 'Директория хранилища не найдена',
              data: {'path': path},
              timestamp: DateTime.now(),
            ),
          ),
        );
        return false;
      }

      await _maintenanceService.deleteStorageDirectory(path);

      final dbHistoryService = await ref.read(dbHistoryProvider.future);
      final historyDeleted = await dbHistoryService.deleteByPath(path);
      if (historyDeleted) {
        logInfo('Store history entry deleted successfully', tag: _logTag);
      } else {
        logWarning('Failed to delete store history entry: $path', tag: _logTag);
      }

      _setState(const DatabaseState(status: DatabaseStatus.idle));

      logInfo('Store deleted from disk successfully', tag: _logTag);
      return true;
    } catch (e, stackTrace) {
      logError(
        'Unexpected error deleting store from disk: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setErrorState(
        DatabaseState(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при удалении хранилища с диска: $e',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );

      return false;
    }
  }

  /// Получить путь к папке вложений
  ///
  /// Возвращает null если хранилище не открыто или ошибка
  Future<String?> getAttachmentsPath() async {
    try {
      if (!_currentState.isOpen) {
        logWarning(
          'Store is not open, cannot get attachments path',
          tag: _logTag,
        );
        return null;
      }

      final storePath = _manager.currentStorePath;
      if (storePath == null || storePath.isEmpty) {
        logError(
          'Failed to get attachments path: store path is null',
          tag: _logTag,
        );
        return null;
      }

      return _maintenanceService.getAttachmentsPath(storePath);
    } catch (e, stackTrace) {
      logError(
        'Unexpected error getting attachments path: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return null;
    }
  }

  Future<String?> getDecryptedAttachmentsPath() async {
    try {
      if (!_currentState.isOpen) {
        logWarning(
          'Store is not open, cannot get decrypted attachments path',
          tag: _logTag,
        );
        return null;
      }

      final storePath = _manager.currentStorePath;
      if (storePath == null || storePath.isEmpty) {
        logError(
          'Failed to get decrypted attachments path: store path is null',
          tag: _logTag,
        );
        return null;
      }

      return _maintenanceService.getDecryptedAttachmentsPath(storePath);
    } catch (e, stackTrace) {
      logError(
        'Unexpected error getting decrypted attachments path: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return null;
    }
  }

  /// Создать подпапку в текущем хранилище
  ///
  /// [folderName] - имя подпапки
  /// Возвращает путь к созданной папке или null при ошибке
  Future<String?> createSubfolder(String folderName) async {
    try {
      if (!_currentState.isOpen) {
        logWarning('Store is not open, cannot create subfolder', tag: _logTag);
        return null;
      }

      final storePath = _manager.currentStorePath;
      if (storePath == null || storePath.isEmpty) {
        logError(
          'Failed to create subfolder: store path is null',
          tag: _logTag,
        );
        return null;
      }

      final path = await _maintenanceService.createSubfolder(
        storePath: storePath,
        folderName: folderName,
      );

      logInfo('Subfolder created: $path', tag: _logTag);
      return path;
    } catch (e, stackTrace) {
      logError(
        'Unexpected error creating subfolder: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return null;
    }
  }

  /// Очистить ошибку из состояния
  void clearError() {
    _cancelErrorResetTimer();
    _setState(_currentState.copyWith(error: null));
  }

  /// Get Current MainStoreManager
  MainStoreManager? get currentMainStoreManager {
    return _manager;
  }

  void _startSnapshotCloseTracking({
    required DateTime initialModifiedAt,
    bool forceUpload = false,
  }) {
    _openedStoreModifiedAt = initialModifiedAt.toUtc();
    _forceSnapshotUploadOnClose = forceUpload;
  }

  void _resetSnapshotCloseTracking() {
    _openedStoreModifiedAt = null;
    _forceSnapshotUploadOnClose = false;
  }

  /// Получить MainStoreManager по готовности

  MainStore get currentDatabase {
    final db = _manager.currentStore;
    if (db == null) {
      logError(
        'Попытка доступа к базе данных, когда она не открыта',
        tag: 'DatabaseAsyncNotifier',
        data: {'state': state.toString()},
      );
      throw DatabaseError.unknown(
        message: 'Database must be opened before accessing it',
        stackTrace: StackTrace.current,
      );
    }
    return db;
  }
}
