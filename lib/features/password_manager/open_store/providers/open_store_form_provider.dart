import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/open_store/models/open_store_state.dart';
import 'package:hoplixi/db_core/models/dto/main_store_dto.dart';
import 'package:hoplixi/db_core/provider/db_history_provider.dart';
import 'package:hoplixi/db_core/provider/main_store_provider.dart';
import 'package:path/path.dart' as p;

final openStoreFormProvider =
    AsyncNotifierProvider.autoDispose<OpenStoreFormNotifier, OpenStoreState>(
      OpenStoreFormNotifier.new,
    );

class OpenStoreFormNotifier extends AsyncNotifier<OpenStoreState> {
  bool get _isMounted => ref.mounted;

  @override
  Future<OpenStoreState> build() async {
    final initialState = const OpenStoreState();
    Future.microtask(loadStorages);
    return initialState;
  }

  OpenStoreState get _currentState => state.value ?? const OpenStoreState();

  void _setState(OpenStoreState newState) {
    state = AsyncData(newState);
  }

  Future<void> loadStorages() async {
    if (!_isMounted) {
      return;
    }

    final currentState = _currentState;
    _setState(currentState.copyWith(isLoading: true, error: null));

    try {
      final storages = <StorageInfo>[];

      final historyStorages = await _loadFromHistory();
      if (!_isMounted) {
        return;
      }
      storages.addAll(historyStorages);

      final folderStorages = await _loadFromFolder();
      if (!_isMounted) {
        return;
      }
      for (final storage in folderStorages) {
        if (!storages.any((item) => item.path == storage.path)) {
          storages.add(storage);
        }
      }

      final backupStorages = await _loadFromBackups();
      if (!_isMounted) {
        return;
      }
      for (final storage in backupStorages) {
        if (!storages.any((item) => item.path == storage.path)) {
          storages.add(storage);
        }
      }

      storages.sort((left, right) {
        if (left.fromHistory && !right.fromHistory) return -1;
        if (!left.fromHistory && right.fromHistory) return 1;

        if (left.fromHistory && right.fromHistory) {
          return (right.lastOpenedAt ?? DateTime(0)).compareTo(
            left.lastOpenedAt ?? DateTime(0),
          );
        }

        return right.modifiedAt.compareTo(left.modifiedAt);
      });

      if (!_isMounted) {
        return;
      }

      _setState(
        _currentState.copyWith(
          storages: storages,
          isLoading: false,
          error: null,
        ),
      );
      logInfo('Loaded ${storages.length} storages', tag: 'OpenStoreForm');
    } catch (error, stackTrace) {
      logError(
        'Error loading storages: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      if (!_isMounted) {
        return;
      }

      _setState(
        _currentState.copyWith(
          isLoading: false,
          error: 'Ошибка загрузки списка хранилищ: $error',
        ),
      );
    }
  }

  void selectStorage(StorageInfo storage) {
    if (!_isMounted) {
      return;
    }

    _setState(
      _currentState.copyWith(
        selectedStorage: storage,
        password: '',
        passwordError: null,
        error: null,
      ),
    );
  }

  void updatePassword(String password) {
    if (!_isMounted) {
      return;
    }

    _setState(_currentState.copyWith(password: password, passwordError: null));
  }

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
      if (!_isMounted) {
        return false;
      }

      if (success) {
        logInfo(
          'Store opened successfully: ${currentState.selectedStorage!.name}',
          tag: 'OpenStoreForm',
        );
        return true;
      }

      final storeState = await ref.read(mainStoreProvider.future);
      if (!_isMounted) {
        return false;
      }

      final errorMessage =
          storeState.error?.message ?? 'Не удалось открыть хранилище';
      _setState(
        _currentState.copyWith(isOpening: false, passwordError: errorMessage),
      );
      return false;
    } catch (error, stackTrace) {
      logError(
        'Error opening store: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      if (!_isMounted) {
        return false;
      }

      _setState(
        _currentState.copyWith(
          isOpening: false,
          error: 'Ошибка при открытии: $error',
        ),
      );
      return false;
    }
  }

  Future<bool> deleteStorage(String path) async {
    try {
      if (!_isMounted) {
        return false;
      }

      final storeNotifier = ref.read(mainStoreProvider.notifier);
      final dir = Directory(path).parent;
      final success = await storeNotifier.deleteStoreFromDisk(dir.path);
      if (!_isMounted) {
        return false;
      }

      if (!success) {
        return false;
      }

      await loadStorages();
      return true;
    } catch (error, stackTrace) {
      logError(
        'Error deleting storage: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      return false;
    }
  }

  void reset() {
    if (!_isMounted) {
      return;
    }
    _setState(const OpenStoreState());
  }

  void cancelSelection() {
    if (!_isMounted) {
      return;
    }

    _setState(
      _currentState.copyWith(
        selectedStorage: null,
        password: '',
        passwordError: null,
      ),
    );
  }

  Future<List<StorageInfo>> _loadFromHistory() async {
    try {
      final historyService = await ref.read(dbHistoryProvider.future);
      if (!_isMounted) {
        return [];
      }

      final history = await historyService.getRecent(limit: 10);
      if (!_isMounted) {
        return [];
      }

      final storages = <StorageInfo>[];
      for (final entry in history) {
        final dir = Directory(entry.path);
        if (!await dir.exists()) {
          continue;
        }

        final files = await dir
            .list()
            .where(
              (entity) =>
                  entity is File &&
                  entity.path.endsWith(MainConstants.dbExtension),
            )
            .toList();
        if (files.isEmpty) {
          continue;
        }

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

      return storages;
    } catch (error, stackTrace) {
      logError(
        'Error loading from history: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      return [];
    }
  }

  Future<List<StorageInfo>> _loadFromFolder() async {
    try {
      final storagePath = await AppPaths.appStoragesPath;
      if (!_isMounted) {
        return [];
      }

      final storageDir = Directory(storagePath);
      if (!await storageDir.exists()) {
        return [];
      }

      final storages = <StorageInfo>[];
      await for (final entity in storageDir.list()) {
        if (entity is! Directory) {
          continue;
        }

        if (!await entity.exists()) {
          continue;
        }

        final files = await entity
            .list()
            .where(
              (item) =>
                  item is File && item.path.endsWith(MainConstants.dbExtension),
            )
            .toList();
        if (files.isEmpty) {
          continue;
        }

        final dbFile = File(files.first.path);
        final stat = await dbFile.stat();
        storages.add(
          StorageInfo(
            name: p.basename(entity.path),
            path: dbFile.path,
            modifiedAt: stat.modified,
            size: stat.size,
            fromHistory: false,
          ),
        );
      }

      return storages;
    } catch (error, stackTrace) {
      logError(
        'Error scanning storage folder: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      return [];
    }
  }

  Future<List<StorageInfo>> _loadFromBackups() async {
    try {
      final backupsPath = await AppPaths.backupsPath;
      if (!_isMounted) {
        return [];
      }

      final backupsDir = Directory(backupsPath);
      if (!await backupsDir.exists()) {
        return [];
      }

      final storages = <StorageInfo>[];
      await for (final entity in backupsDir.list(recursive: false)) {
        if (entity is! Directory) {
          continue;
        }

        final files = await entity
            .list(recursive: false)
            .where(
              (item) =>
                  item is File && item.path.endsWith(MainConstants.dbExtension),
            )
            .toList();
        if (files.isEmpty) {
          continue;
        }

        final dbFile = File(files.first.path);
        final stat = await dbFile.stat();
        storages.add(
          StorageInfo(
            name: p.basename(entity.path),
            path: dbFile.path,
            modifiedAt: stat.modified,
            size: stat.size,
            fromHistory: false,
            description: 'Бэкап',
          ),
        );
      }

      return storages;
    } catch (error, stackTrace) {
      logError(
        'Error scanning backups folder: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      return [];
    }
  }
}
