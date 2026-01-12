import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/main_store_manager.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:hoplixi/main_store/models/db_state.dart';
import 'package:hoplixi/main_store/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_store/provider/db_history_provider.dart';

final _mainStoreManagerProvider = FutureProvider<MainStoreManager>((ref) async {
  final dbHistoryService = await ref.read(dbHistoryProvider.future);
  final manager = MainStoreManager(dbHistoryService);

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
  final state = await ref.watch(mainStoreProvider.future);
  return state;
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
        return manager.currentStore!.watchDataChanged();
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

  /// Completer для блокировки параллельных операций (защита от race condition)
  Completer<void>? _operationLock;

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
    return const DatabaseState(status: DatabaseStatus.idle);
  }

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

          logInfo(
            'Store created successfully: ${storeInfo.name}',
            tag: _logTag,
          );
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

          logInfo('Store opened successfully: ${storeInfo.name}', tag: _logTag);
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

    try {
      logInfo('Closing store', tag: _logTag);

      if (!_currentState.isOpen) {
        logWarning('Store is not open, cannot close', tag: _logTag);
        return false;
      }

      // Устанавливаем состояние загрузки
      _setState(
        _currentState.copyWith(status: DatabaseStatus.loading, error: null),
      );

      // Вызываем закрытие хранилища
      final result = await _manager.closeStore();

      return result.fold(
        (_) {
          // Успех - переводим в idle состояние
          _setState(const DatabaseState(status: DatabaseStatus.closed));
          _setState(const DatabaseState(status: DatabaseStatus.idle));

          logInfo('Store closed successfully', tag: _logTag);
          return true;
        },
        (error) {
          // Ошибка - возвращаем предыдущее состояние с ошибкой и автосбросом
          _setErrorState(
            _currentState.copyWith(status: DatabaseStatus.error, error: error),
          );

          logError('Failed to close store: ${error.message}', tag: _logTag);
          return false;
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Unexpected error closing store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );

      _setErrorState(
        _currentState.copyWith(
          status: DatabaseStatus.error,
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
  Future<void> lockStore() async {
    if (!_currentState.isOpen) {
      logWarning('Store is not open, cannot lock', tag: _logTag);
      return;
    }

    logInfo('Locking store', tag: _logTag);

    final currentPath = _currentState.path;
    final currentName = _currentState.name;

    // Закрываем соединение
    await _manager.closeStore();

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

      // Вызываем удаление хранилища
      final result = await _manager.deleteStore(
        path,
        deleteFromDisk: deleteFromDisk,
      );

      return result.fold(
        (_) {
          // Успех - переводим в idle состояние
          _setState(const DatabaseState(status: DatabaseStatus.idle));

          logInfo('Store deleted successfully', tag: _logTag);
          return true;
        },
        (error) {
          // Ошибка - сохраняем в состоянии с автосбросом
          _setErrorState(
            DatabaseState(status: DatabaseStatus.error, error: error),
          );

          logError('Failed to delete store: ${error.message}', tag: _logTag);
          return false;
        },
      );
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

      // Вызываем удаление хранилища с диска
      final result = await _manager.deleteStoreFromDisk(path);
      final historyResult = await _manager.deleteStoreFromHistory(path);

      final resultDeleteFromDisk = result.fold(
        (_) {
          // Успех - переводим в idle состояние
          _setState(const DatabaseState(status: DatabaseStatus.idle));

          logInfo('Store deleted from disk successfully', tag: _logTag);
          return true;
        },
        (error) {
          // Ошибка - сохраняем в состоянии с автосбросом
          _setErrorState(
            DatabaseState(status: DatabaseStatus.error, error: error),
          );

          logError(
            'Failed to delete store from disk: ${error.message}',
            tag: _logTag,
          );
          return false;
        },
      );

      historyResult.fold(
        (_) {
          logInfo('Store history entry deleted successfully', tag: _logTag);
        },
        (error) {
          logError(
            'Failed to delete store history entry: ${error.message}',
            tag: _logTag,
          );
        },
      );

      return resultDeleteFromDisk;
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

      final result = await _manager.getAttachmentsPath();

      return result.fold((path) => path, (error) {
        logError(
          'Failed to get attachments path: ${error.message}',
          tag: _logTag,
        );
        return null;
      });
    } catch (e, stackTrace) {
      logError(
        'Unexpected error getting attachments path: $e',
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

      final result = await _manager.createSubfolder(folderName);

      return result.fold(
        (path) {
          logInfo('Subfolder created: $path', tag: _logTag);
          return path;
        },
        (error) {
          logError(
            'Failed to create subfolder: ${error.message}',
            tag: _logTag,
          );
          return null;
        },
      );
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
