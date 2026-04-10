import 'package:hive_ce/hive.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/di_init.dart';
import 'package:hoplixi/db_core/models/db_history_model.dart';

/// Сервис для работы с историей баз данных
///
/// Управляет CRUD операциями для DatabaseEntry с использованием
/// зашифрованного Hive бокса через HiveBoxManager
class DatabaseHistoryService {
  static const String _boxName = 'database_history';
  static const String _logTag = 'DatabaseHistoryService';

  final HiveBoxManager _hiveManager;
  Box<Map>? _box;

  DatabaseHistoryService() : _hiveManager = getIt<HiveBoxManager>();

  /// Инициализация сервиса и открытие бокса
  Future<void> initialize() async {
    try {
      _box = await _hiveManager.openBox<Map>(_boxName);
      logInfo('DatabaseHistoryService initialized', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Failed to initialize DatabaseHistoryService: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Проверка инициализации бокса
  void _ensureInitialized() {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'DatabaseHistoryService is not initialized. Call initialize() first.',
      );
    }
  }

  /// Создать новую запись базы данных
  ///
  /// Автоматически генерирует уникальный dbId и устанавливает createdAt
  Future<DatabaseEntry> create({
    required String path,
    required String dbId,
    required String name,
    String? description,
    String? password,
    bool savePassword = false,
  }) async {
    _ensureInitialized();

    try {
      final entry = DatabaseEntry(
        dbId: dbId,
        path: path,
        name: name,
        description: description,
        password: password,
        savePassword: savePassword,
        createdAt: DateTime.now(),
        lastAccessed: null,
      );

      await _box!.put(entry.path, entry.toJson());
      logInfo(
        'Created database entry: ${entry.name} at ${entry.path}',
        tag: _logTag,
      );

      return entry;
    } catch (e, stackTrace) {
      logError(
        'Failed to create database entry: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Получить запись по пути к файлу (primary key)
  Future<DatabaseEntry?> getByPath(String path) async {
    _ensureInitialized();

    try {
      final data = _box!.get(path);
      if (data == null) {
        logInfo('Database entry not found: $path', tag: _logTag);
        return null;
      }

      return DatabaseEntry.fromJson(Map<String, dynamic>.from(data));
    } catch (e, stackTrace) {
      logError(
        'Failed to get database entry by path $path: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return null;
    }
  }

  /// Получить запись по dbId
  Future<DatabaseEntry?> getById(String dbId) async {
    _ensureInitialized();

    try {
      final entries = await getAll();
      return entries.firstWhere(
        (entry) => entry.dbId == dbId,
        orElse: () => throw StateError('Not found'),
      );
    } catch (e) {
      logInfo('Database entry not found by id: $dbId', tag: _logTag);
      return null;
    }
  }

  /// Получить все записи
  Future<List<DatabaseEntry>> getAll() async {
    _ensureInitialized();

    try {
      final entries = <DatabaseEntry>[];
      for (final data in _box!.values) {
        try {
          final entry = DatabaseEntry.fromJson(Map<String, dynamic>.from(data));
          entries.add(entry);
        } catch (e) {
          logWarning('Failed to parse database entry: $e', tag: _logTag);
        }
      }

      logInfo('Retrieved ${entries.length} database entries', tag: _logTag);
      return entries;
    } catch (e, stackTrace) {
      logError(
        'Failed to get all database entries: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return [];
    }
  }

  /// Получить записи отсортированные по последнему доступу
  Future<List<DatabaseEntry>> getRecent({int limit = 10}) async {
    _ensureInitialized();

    try {
      final entries = await getAll();
      entries.sort((a, b) {
        // Используем lastAccessed, если есть, иначе createdAt
        final aDate = a.lastAccessed ?? a.createdAt ?? DateTime(1970);
        final bDate = b.lastAccessed ?? b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return entries.take(limit).toList();
    } catch (e, stackTrace) {
      logError(
        'Failed to get recent database entries: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return [];
    }
  }

  /// Обновить запись
  Future<DatabaseEntry> update(DatabaseEntry entry) async {
    _ensureInitialized();

    try {
      await _box!.put(entry.path, entry.toJson());
      logInfo(
        'Updated database entry: ${entry.name} at ${entry.path}',
        tag: _logTag,
      );

      return entry;
    } catch (e, stackTrace) {
      logError(
        'Failed to update database entry at ${entry.path}: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Обновить время последнего доступа по пути
  Future<DatabaseEntry?> updateLastAccessed(String path) async {
    _ensureInitialized();

    try {
      final entry = await getByPath(path);
      if (entry == null) {
        logWarning(
          'Cannot update lastAccessed: entry at $path not found',
          tag: _logTag,
        );
        return null;
      }

      final updatedEntry = entry.copyWith(lastAccessed: DateTime.now());
      await update(updatedEntry);

      return updatedEntry;
    } catch (e, stackTrace) {
      logError(
        'Failed to update lastAccessed for $path: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return null;
    }
  }

  /// Удалить запись по пути (primary key)
  Future<bool> deleteByPath(String path) async {
    _ensureInitialized();

    try {
      await _box!.delete(path);
      logInfo('Deleted database entry at: $path', tag: _logTag);

      return true;
    } catch (e, stackTrace) {
      logError(
        'Failed to delete database entry at $path: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return false;
    }
  }

  /// Удалить запись по dbId
  Future<bool> deleteById(String dbId) async {
    _ensureInitialized();

    try {
      final entry = await getById(dbId);
      if (entry == null) {
        logWarning(
          'Cannot delete: entry with id $dbId not found',
          tag: _logTag,
        );
        return false;
      }

      await _box!.delete(entry.path);
      logInfo('Deleted database entry: $dbId at ${entry.path}', tag: _logTag);

      return true;
    } catch (e, stackTrace) {
      logError(
        'Failed to delete database entry $dbId: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return false;
    }
  }

  /// Удалить все записи
  Future<bool> deleteAll() async {
    _ensureInitialized();

    try {
      await _box!.clear();
      logInfo('Deleted all database entries', tag: _logTag);

      return true;
    } catch (e, stackTrace) {
      logError(
        'Failed to delete all database entries: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return false;
    }
  }

  /// Проверить существование записи по пути (primary key)
  Future<bool> existsByPath(String path) async {
    _ensureInitialized();

    try {
      return _box!.containsKey(path);
    } catch (e) {
      logError('Failed to check existence of entry at $path: $e', tag: _logTag);
      return false;
    }
  }

  /// Проверить существование записи по dbId
  Future<bool> existsById(String dbId) async {
    _ensureInitialized();

    try {
      final entry = await getById(dbId);
      return entry != null;
    } catch (e) {
      logError('Failed to check existence of entry $dbId: $e', tag: _logTag);
      return false;
    }
  }

  /// Получить количество записей
  Future<int> count() async {
    _ensureInitialized();

    try {
      return _box!.length;
    } catch (e) {
      logError('Failed to get count of entries: $e', tag: _logTag);
      return 0;
    }
  }

  /// Поиск записей по имени или описанию
  Future<List<DatabaseEntry>> search(String query) async {
    _ensureInitialized();

    try {
      if (query.isEmpty) return await getAll();

      final entries = await getAll();
      final lowerQuery = query.toLowerCase();

      return entries.where((entry) {
        final nameMatch = entry.name.toLowerCase().contains(lowerQuery);
        final descMatch =
            entry.description?.toLowerCase().contains(lowerQuery) ?? false;
        final pathMatch = entry.path.toLowerCase().contains(lowerQuery);

        return nameMatch || descMatch || pathMatch;
      }).toList();
    } catch (e, stackTrace) {
      logError(
        'Failed to search database entries: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return [];
    }
  }

  /// Экспортировать все записи в JSON
  Future<List<Map<String, dynamic>>> exportToJson() async {
    _ensureInitialized();

    try {
      final entries = await getAll();
      return entries.map((e) => e.toJson()).toList();
    } catch (e, stackTrace) {
      logError(
        'Failed to export database entries: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return [];
    }
  }

  /// Импортировать записи из JSON
  Future<int> importFromJson(List<Map<String, dynamic>> jsonList) async {
    _ensureInitialized();

    try {
      int imported = 0;
      for (final json in jsonList) {
        try {
          final entry = DatabaseEntry.fromJson(json);
          await _box!.put(entry.path, entry.toJson());
          imported++;
        } catch (e) {
          logWarning('Failed to import entry: $e', tag: _logTag);
        }
      }

      logInfo('Imported $imported database entries', tag: _logTag);
      return imported;
    } catch (e, stackTrace) {
      logError(
        'Failed to import database entries: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return 0;
    }
  }

  /// Закрыть бокс и освободить ресурсы
  Future<void> dispose() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _hiveManager.closeBox(_boxName);
        _box = null;
        logInfo('DatabaseHistoryService disposed', tag: _logTag);
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to dispose DatabaseHistoryService: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }
}
