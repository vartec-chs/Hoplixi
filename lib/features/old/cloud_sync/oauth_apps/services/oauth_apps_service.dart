import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_ce/hive.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/models/oauth_apps.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/models/oauth_apps_errors.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Сервис для управления OAuth приложениями
///
/// Использует HiveBoxManager для безопасного хранения данных OAuth приложений.
/// Все операции возвращают AsyncResult для обработки ошибок.
class OAuthAppsService {
  static const String _boxName = 'oauth_apps';
  static const String _logTag = 'OAuthAppsService';

  final HiveBoxManager _hiveManager;
  Box<Map<dynamic, dynamic>>? _box;

  OAuthAppsService(this._hiveManager);

  /// Инициализация сервиса (открытие бокса)
  AsyncResultDart<void, OAuthAppsError> initialize() async {
    try {
      logInfo('Initializing OAuthAppsService', tag: _logTag);
      _box = await _hiveManager.openBox<Map<dynamic, dynamic>>(_boxName);
      logInfo('OAuthAppsService initialized successfully', tag: _logTag);

      // Загружаем встроенные приложения
      await _loadBuiltinApps();

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to initialize OAuthAppsService: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось инициализировать хранилище OAuth приложений',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Проверка, что бокс открыт
  void _ensureInitialized() {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'OAuthAppsService not initialized. Call initialize() first.',
      );
    }
  }

  /// Загрузить встроенные OAuth приложения из .env
  Future<void> _loadBuiltinApps() async {
    try {
      // Проверяем, включены ли встроенные приложения
      final useBuiltin =
          dotenv.env['USED_BUILTIN_AUTH_APPS']?.toLowerCase() == 'true';
      if (!useBuiltin) {
        logInfo('Builtin OAuth apps are disabled', tag: _logTag);
        return;
      }

      logInfo('Loading builtin OAuth apps', tag: _logTag);
      final builtinApps = <OauthApps>[];

      // Загрузка Google
      if (_isBuiltinEnabled('GOOGLE')) {
        final app = _createBuiltinApp(
          type: OauthAppsType.google,
          prefix: 'GOOGLE',
        );
        if (app != null) {
          builtinApps.add(app);
        }
      }

      // Загрузка Dropbox
      if (_isBuiltinEnabled('DROPBOX')) {
        final app = _createBuiltinApp(
          type: OauthAppsType.dropbox,
          prefix: 'DROPBOX',
        );
        if (app != null) {
          builtinApps.add(app);
        }
      }

      // Загрузка Yandex
      if (_isBuiltinEnabled('YANDEX')) {
        final app = _createBuiltinApp(
          type: OauthAppsType.yandex,
          prefix: 'YANDEX',
        );
        if (app != null) {
          builtinApps.add(app);
        }
      }

      // Загрузка OneDrive
      if (_isBuiltinEnabled('ONEDRIVE')) {
        final app = _createBuiltinApp(
          type: OauthAppsType.onedrive,
          prefix: 'ONEDRIVE',
        );
        if (app != null) {
          builtinApps.add(app);
        }
      }

      // Сохраняем встроенные приложения
      for (final app in builtinApps) {
        // Проверяем, существует ли уже это приложение
        if (!_box!.containsKey(app.id)) {
          final data = app.toJson();
          await _box!.put(app.id, data);
          logInfo(
            'Loaded builtin OAuth app: ${app.name} (${app.type.name})',
            tag: _logTag,
          );
        } else {
          // Обновляем существующее встроенное приложение
          final existingData = _box!.get(app.id);
          if (existingData != null) {
            final existing = OauthApps.fromJson(
              Map<String, dynamic>.from(existingData),
            );
            if (existing.isBuiltin) {
              // Обновляем учетные данные для встроенного приложения
              final data = app.toJson();
              await _box!.put(app.id, data);
              logInfo(
                'Updated builtin OAuth app: ${app.name} (${app.type.name})',
                tag: _logTag,
              );
            }
          }
        }
      }

      logInfo('Loaded ${builtinApps.length} builtin OAuth apps', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Failed to load builtin OAuth apps: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      // Не прерываем инициализацию, просто логируем ошибку
    }
  }

  /// Проверить, включено ли встроенное приложение
  bool _isBuiltinEnabled(String prefix) {
    final enabled =
        dotenv.env['${prefix}_BUILTIN_ENABLED']?.toLowerCase() == 'true';
    return enabled;
  }

  /// Создать встроенное OAuth приложение из переменных окружения
  OauthApps? _createBuiltinApp({
    required OauthAppsType type,
    required String prefix,
  }) {
    try {
      final name = dotenv.env['${prefix}_APP_NAME'];
      final clientId = dotenv.env['${prefix}_CLIENT_ID'];
      final clientSecret = dotenv.env['${prefix}_CLIENT_SECRET'];

      if (name == null || name.isEmpty) {
        logWarning('Missing ${prefix}_APP_NAME in .env', tag: _logTag);
        return null;
      }

      if (clientId == null || clientId.isEmpty) {
        logWarning('Missing ${prefix}_CLIENT_ID in .env', tag: _logTag);
        return null;
      }

      // Создаем детерминированный ID для встроенного приложения
      final id = 'builtin-${type.identifier}';

      return OauthApps(
        id: id,
        name: name,
        type: type,
        clientId: clientId,
        clientSecret: (clientSecret != null && clientSecret.isNotEmpty)
            ? clientSecret
            : null,
        isBuiltin: true,
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to create builtin OAuth app for $prefix: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return null;
    }
  }

  /// Получить OAuth приложение по ID
  AsyncResultDart<OauthApps, OAuthAppsError> getApp(String id) async {
    try {
      _ensureInitialized();

      final data = _box!.get(id);
      if (data == null) {
        logInfo('OAuth app not found: $id', tag: _logTag);
        return Failure(
          OAuthAppsError.notFound(data: {'id': id}, timestamp: DateTime.now()),
        );
      }

      final app = OauthApps.fromJson(Map<String, dynamic>.from(data));
      logInfo('Retrieved OAuth app: $id', tag: _logTag);
      return Success(app);
    } catch (e, stackTrace) {
      logError(
        'Failed to get OAuth app: $id - $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.serializationError(
          message: 'Не удалось прочитать данные OAuth приложения',
          data: {'id': id, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Получить все OAuth приложения
  AsyncResultDart<List<OauthApps>, OAuthAppsError> getAllApps() async {
    try {
      _ensureInitialized();

      final apps = <OauthApps>[];
      for (final key in _box!.keys) {
        final data = _box!.get(key);
        if (data != null) {
          try {
            final app = OauthApps.fromJson(Map<String, dynamic>.from(data));
            apps.add(app);
          } catch (e) {
            logWarning(
              'Skipping invalid OAuth app data for key: $key - $e',
              tag: _logTag,
            );
          }
        }
      }

      logInfo('Retrieved ${apps.length} OAuth apps', tag: _logTag);
      return Success(apps);
    } catch (e, stackTrace) {
      logError(
        'Failed to get all OAuth apps: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось получить список OAuth приложений',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Получить OAuth приложения по типу
  AsyncResultDart<List<OauthApps>, OAuthAppsError> getAppsByType(
    OauthAppsType type,
  ) async {
    try {
      final result = await getAllApps();
      return result.map(
        (apps) => apps.where((app) => app.type == type).toList(),
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to get OAuth apps by type: $type - $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось получить OAuth приложения по типу',
          data: {'type': type.name, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Получить встроенные OAuth приложения
  AsyncResultDart<List<OauthApps>, OAuthAppsError> getBuiltinApps() async {
    try {
      final result = await getAllApps();
      return result.map((apps) => apps.where((app) => app.isBuiltin).toList());
    } catch (e, stackTrace) {
      logError(
        'Failed to get builtin OAuth apps: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось получить встроенные OAuth приложения',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Получить пользовательские OAuth приложения
  AsyncResultDart<List<OauthApps>, OAuthAppsError> getCustomApps() async {
    try {
      final result = await getAllApps();
      return result.map((apps) => apps.where((app) => !app.isBuiltin).toList());
    } catch (e, stackTrace) {
      logError(
        'Failed to get custom OAuth apps: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось получить пользовательские OAuth приложения',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Создать или обновить OAuth приложение
  AsyncResultDart<void, OAuthAppsError> saveApp(OauthApps app) async {
    try {
      _ensureInitialized();

      // Валидация данных
      if (app.id.isEmpty) {
        return const Failure(
          OAuthAppsError.invalidData(
            message: 'ID OAuth приложения не может быть пустым',
          ),
        );
      }

      if (app.clientId.isEmpty) {
        return const Failure(
          OAuthAppsError.invalidData(message: 'Client ID не может быть пустым'),
        );
      }

      final data = app.toJson();
      await _box!.put(app.id, data);
      logInfo('Saved OAuth app: ${app.id}', tag: _logTag);
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to save OAuth app: ${app.id} - $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось сохранить OAuth приложение',
          data: {'id': app.id, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Создать новое OAuth приложение
  /// Проверяет, что приложение с таким ID не существует
  AsyncResultDart<void, OAuthAppsError> createApp(OauthApps app) async {
    try {
      _ensureInitialized();

      if (_box!.containsKey(app.id)) {
        logWarning('OAuth app already exists: ${app.id}', tag: _logTag);
        return Failure(
          OAuthAppsError.alreadyExists(
            data: {'id': app.id},
            timestamp: DateTime.now(),
          ),
        );
      }

      return await saveApp(app);
    } catch (e, stackTrace) {
      logError(
        'Failed to create OAuth app: ${app.id} - $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось создать OAuth приложение',
          data: {'id': app.id, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Обновить существующее OAuth приложение
  /// Проверяет, что приложение с таким ID существует
  AsyncResultDart<void, OAuthAppsError> updateApp(OauthApps app) async {
    try {
      _ensureInitialized();

      if (!_box!.containsKey(app.id)) {
        logWarning('OAuth app not found for update: ${app.id}', tag: _logTag);
        return Failure(
          OAuthAppsError.notFound(
            data: {'id': app.id},
            timestamp: DateTime.now(),
          ),
        );
      }

      // Проверяем, не пытается ли пользователь изменить встроенное приложение
      final existingData = _box!.get(app.id);
      if (existingData != null) {
        final existing = OauthApps.fromJson(
          Map<String, dynamic>.from(existingData),
        );
        if (existing.isBuiltin) {
          logWarning(
            'Attempted to update builtin OAuth app: ${app.id}',
            tag: _logTag,
          );
          return const Failure(
            OAuthAppsError.invalidData(
              message: 'Встроенные OAuth приложения нельзя редактировать',
            ),
          );
        }
      }

      return await saveApp(app);
    } catch (e, stackTrace) {
      logError(
        'Failed to update OAuth app: ${app.id} - $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось обновить OAuth приложение',
          data: {'id': app.id, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Удалить OAuth приложение
  AsyncResultDart<void, OAuthAppsError> deleteApp(String id) async {
    try {
      _ensureInitialized();

      if (!_box!.containsKey(id)) {
        logWarning('OAuth app not found for deletion: $id', tag: _logTag);
        return Failure(
          OAuthAppsError.notFound(data: {'id': id}, timestamp: DateTime.now()),
        );
      }

      // Проверяем, не пытается ли пользователь удалить встроенное приложение
      final existingData = _box!.get(id);
      if (existingData != null) {
        final existing = OauthApps.fromJson(
          Map<String, dynamic>.from(existingData),
        );
        if (existing.isBuiltin) {
          logWarning(
            'Attempted to delete builtin OAuth app: $id',
            tag: _logTag,
          );
          return const Failure(
            OAuthAppsError.invalidData(
              message: 'Встроенные OAuth приложения нельзя удалять',
            ),
          );
        }
      }

      await _box!.delete(id);
      logInfo('Deleted OAuth app: $id', tag: _logTag);
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to delete OAuth app: $id - $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось удалить OAuth приложение',
          data: {'id': id, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Удалить несколько OAuth приложений
  AsyncResultDart<void, OAuthAppsError> deleteApps(List<String> ids) async {
    try {
      _ensureInitialized();

      await _box!.deleteAll(ids);
      logInfo('Deleted ${ids.length} OAuth apps', tag: _logTag);
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to delete OAuth apps: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось удалить OAuth приложения',
          data: {'count': ids.length, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Очистить все OAuth приложения
  AsyncResultDart<void, OAuthAppsError> clearAll() async {
    try {
      _ensureInitialized();

      final count = await _box!.clear();
      logInfo('Cleared all OAuth apps (count: $count)', tag: _logTag);
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to clear all OAuth apps: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось очистить все OAuth приложения',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Проверить, существует ли OAuth приложение
  bool appExists(String id) {
    _ensureInitialized();
    return _box!.containsKey(id);
  }

  /// Получить количество OAuth приложений
  int getCount() {
    _ensureInitialized();
    return _box!.length;
  }

  /// Подписка на изменения OAuth приложений
  Stream<BoxEvent> watchChanges({String? appId}) {
    _ensureInitialized();
    return _box!.watch(key: appId);
  }

  /// Экспортировать все OAuth приложения
  AsyncResultDart<Map<String, OauthApps>, OAuthAppsError> exportAll() async {
    try {
      final result = await getAllApps();
      return result.map((apps) {
        return {for (final app in apps) app.id: app};
      });
    } catch (e, stackTrace) {
      logError(
        'Failed to export OAuth apps: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось экспортировать OAuth приложения',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Импортировать OAuth приложения
  AsyncResultDart<int, OAuthAppsError> importAll(
    Map<String, OauthApps> apps, {
    bool overwrite = false,
  }) async {
    try {
      _ensureInitialized();

      var imported = 0;
      for (final entry in apps.entries) {
        final id = entry.key;
        final app = entry.value;

        if (!overwrite && _box!.containsKey(id)) {
          logInfo('Skipping existing OAuth app: $id', tag: _logTag);
          continue;
        }

        final result = await saveApp(app);
        if (result.isSuccess()) {
          imported++;
        }
      }

      logInfo('Imported $imported OAuth apps', tag: _logTag);
      return Success(imported);
    } catch (e, stackTrace) {
      logError(
        'Failed to import OAuth apps: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось импортировать OAuth приложения',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Компактировать хранилище (оптимизация)
  AsyncResultDart<void, OAuthAppsError> compact() async {
    try {
      _ensureInitialized();

      await _hiveManager.compactBox(_boxName);
      logInfo('Compacted OAuth apps storage', tag: _logTag);
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to compact OAuth apps storage: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось компактировать хранилище OAuth приложений',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Перезагрузить встроенные OAuth приложения из .env
  /// Полезно после изменения переменных окружения
  AsyncResultDart<void, OAuthAppsError> reloadBuiltinApps() async {
    try {
      _ensureInitialized();
      logInfo('Reloading builtin OAuth apps', tag: _logTag);
      await _loadBuiltinApps();
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to reload builtin OAuth apps: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        OAuthAppsError.storageError(
          message: 'Не удалось перезагрузить встроенные OAuth приложения',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Закрыть сервис
  Future<void> dispose() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _hiveManager.closeBox(_boxName);
        _box = null;
        logInfo('OAuthAppsService disposed', tag: _logTag);
      }
    } catch (e, stackTrace) {
      logError(
        'Error disposing OAuthAppsService: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }
}
