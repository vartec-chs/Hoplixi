import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/open_store/models/open_store_state.dart';
import 'package:hoplixi/main_store/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_store/provider/db_history_provider.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:path/path.dart' as p;

/// Провайдер для формы открытия хранилища
final openStoreFormProvider =
    AsyncNotifierProvider.autoDispose<OpenStoreFormNotifier, OpenStoreState>(
      OpenStoreFormNotifier.new,
    );

/// Notifier для управления состоянием формы открытия хранилища
class OpenStoreFormNotifier extends AsyncNotifier<OpenStoreState> {
  @override
  Future<OpenStoreState> build() async {
    // Загружаем хранилища при инициализации
    final initialState = const OpenStoreState();
    // Запускаем загрузку асинхронно
    Future.microtask(() => loadStorages());
    return initialState;
  }

  /// Получить текущее состояние или значение по умолчанию
  OpenStoreState get _currentState {
    return state.value ?? const OpenStoreState();
  }

  /// Установить новое состояние
  void _setState(OpenStoreState newState) {
    state = AsyncData(newState);
  }

  /// Загрузить список хранилищ из истории и папки
  Future<void> loadStorages() async {
    final currentState = _currentState;
    _setState(currentState.copyWith(isLoading: true, error: null));

    try {
      final storages = <StorageInfo>[];

      // 1. Загрузить из истории
      final historyStorages = await _loadFromHistory();
      logTrace(
        'Loaded ${historyStorages.length} storages from history',
        tag: 'OpenStoreForm',
      );
      storages.addAll(historyStorages);

      // 2. Сканировать папку хранилищ
      final folderStorages = await _loadFromFolder();
      logTrace(
        'Loaded ${folderStorages.length} storages from folder',
        tag: 'OpenStoreForm',
      );

      // Добавить только те, которых нет в истории
      for (final storage in folderStorages) {
        if (!storages.any((s) => s.path == storage.path)) {
          storages.add(storage);
        }
      }

      // Сортировать: сначала из истории по времени, потом из папки по дате изменения
      storages.sort((a, b) {
        if (a.fromHistory && !b.fromHistory) return -1;
        if (!a.fromHistory && b.fromHistory) return 1;

        if (a.fromHistory && b.fromHistory) {
          return (b.lastOpenedAt ?? DateTime(0)).compareTo(
            a.lastOpenedAt ?? DateTime(0),
          );
        }

        return b.modifiedAt.compareTo(a.modifiedAt);
      });

      final updatedState = _currentState;
      _setState(
        updatedState.copyWith(
          storages: storages,
          isLoading: false,
          error: null,
        ),
      );

      logInfo('Loaded ${storages.length} storages', tag: 'OpenStoreForm');
    } catch (e, stackTrace) {
      logError(
        'Error loading storages: $e',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );

      final updatedState = _currentState;
      _setState(
        updatedState.copyWith(
          isLoading: false,
          error: 'Ошибка загрузки списка хранилищ: $e',
        ),
      );
    }
  }

  /// Загрузить хранилища из истории
  Future<List<StorageInfo>> _loadFromHistory() async {
    try {
      final historyService = await ref.read(dbHistoryProvider.future);
      final history = await historyService.getRecent(limit: 10);

      logTrace(
        'Fetched ${history.length} history entries',
        tag: 'OpenStoreForm',
      );

      final storages = <StorageInfo>[];

      for (final entry in history) {
        final dir = Directory(entry.path);

        // Проверяем, существует ли директория
        if (!await dir.exists()) continue;

        // Ищем файл с нужным расширением в директории
        final files = await dir
            .list()
            .where(
              (entity) =>
                  entity is File &&
                  entity.path.endsWith(MainConstants.dbExtension),
            )
            .toList();

        if (files.isEmpty) continue;

        final dbFile = File(files.first.path);

        final stat = await dbFile.stat();

        storages.add(
          StorageInfo(
            name: entry.name,
            path: dbFile.path,
            modifiedAt: stat.modified,
            description: entry.description,
            size: stat.size,
            fromHistory: true,
            lastOpenedAt: entry.lastAccessed,
          ),
        );
      }

      logTrace(
        'Loaded ${storages.length} storages from history',
        tag: 'OpenStoreForm',
      );

      return storages;
    } catch (e, stackTrace) {
      logError(
        'Error loading from history: $e',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      return [];
    }
  }

  /// Сканировать папку хранилищ
  Future<List<StorageInfo>> _loadFromFolder() async {
    try {
      final storagePath = await AppPaths.appStoragePath;
      final storageDir = Directory(storagePath);

      if (!await storageDir.exists()) {
        logWarning('Storage directory does not exist', tag: 'OpenStoreForm');
        return [];
      }

      final storages = <StorageInfo>[];

      // Ищем поддиректории (каждое хранилище в своей папке)
      await for (final entity in storageDir.list()) {
        if (entity is Directory) {
          // Проверяем, существует ли директория
          if (!await entity.exists()) continue;

          // Ищем файлы с нужным расширением
          final files = await entity
              .list()
              .where(
                (item) =>
                    item is File &&
                    item.path.endsWith(MainConstants.dbExtension),
              )
              .toList();

          if (files.isNotEmpty) {
            final dbFile = File(files.first.path);
            final stat = await dbFile.stat();
            final dirName = p.basename(entity.path);

            storages.add(
              StorageInfo(
                name: dirName,
                path: dbFile.path,
                modifiedAt: stat.modified,
                size: stat.size,
                fromHistory: false,
              ),
            );
          }
        }
      }

      return storages;
    } catch (e, stackTrace) {
      logError(
        'Error scanning storage folder: $e',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      return [];
    }
  }

  /// Выбрать хранилище
  void selectStorage(StorageInfo storage) {
    final currentState = _currentState;
    _setState(
      currentState.copyWith(
        selectedStorage: storage,
        password: '',
        passwordError: null,
        error: null,
      ),
    );
  }

  /// Обновить пароль
  void updatePassword(String password) {
    final currentState = _currentState;
    _setState(currentState.copyWith(password: password, passwordError: null));
  }

  /// Открыть выбранное хранилище
  Future<bool> openStorage() async {
    final currentState = _currentState;

    if (currentState.selectedStorage == null) {
      _setState(currentState.copyWith(error: 'Хранилище не выбрано'));
      return false;
    }

    if (currentState.password.isEmpty) {
      _setState(currentState.copyWith(passwordError: 'Введите пароль'));
      return false;
    }

    _setState(
      currentState.copyWith(isOpening: true, passwordError: null, error: null),
    );

    try {
      final dto = OpenStoreDto(
        path: currentState.selectedStorage!.path,
        password: currentState.password,
      );

      final storeNotifier = ref.read(mainStoreProvider.notifier);
      final success = await storeNotifier.openStore(dto);

      if (success) {
        logInfo(
          'Store opened successfully: ${currentState.selectedStorage!.name}',
          tag: 'OpenStoreForm',
        );
        return true;
      } else {
        final storeState = await ref.read(mainStoreProvider.future);
        final errorMessage =
            storeState.error?.message ?? 'Не удалось открыть хранилище';

        final updatedState = _currentState;
        _setState(
          updatedState.copyWith(isOpening: false, passwordError: errorMessage),
        );

        logWarning('Failed to open store: $errorMessage', tag: 'OpenStoreForm');
        return false;
      }
    } catch (e, stackTrace) {
      logError(
        'Error opening store: $e',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );

      final updatedState = _currentState;
      _setState(
        updatedState.copyWith(
          isOpening: false,
          error: 'Ошибка при открытии: $e',
        ),
      );

      return false;
    }
  }

  /// Удалить хранилище с диска
  Future<bool> deleteStorage(String path) async {
    try {
      logInfo('Deleting storage at: $path', tag: 'OpenStoreForm');

      final storeNotifier = ref.read(mainStoreProvider.notifier);

      // Получаем путь к директории из пути к файлу
      final dir = Directory(path).parent;
      final success = await storeNotifier.deleteStoreFromDisk(dir.path);
      

      if (success) {
        logInfo('Storage deleted successfully', tag: 'OpenStoreForm');

        // Перезагрузить список хранилищ
        await loadStorages();

        return true;
      } else {
        logWarning('Failed to delete storage', tag: 'OpenStoreForm');
        return false;
      }
    } catch (e, stackTrace) {
      logError(
        'Error deleting storage: $e',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      return false;
    }
  }

  /// Сбросить состояние
  void reset() {
    _setState(const OpenStoreState());
  }

  /// Отменить выбор хранилища
  void cancelSelection() {
    final currentState = _currentState;
    _setState(
      currentState.copyWith(
        selectedStorage: null,
        password: '',
        passwordError: null,
      ),
    );
  }
}
