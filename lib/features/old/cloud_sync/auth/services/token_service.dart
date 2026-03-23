import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/models/token_oauth.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/models/token_service_errors.dart';
import 'package:result_dart/result_dart.dart';
import 'package:cloud_storage_all/cloud_storage_all.dart'
    show OAuth2TokenStorage, OAuth2TokenF;

/// Сервис для управления OAuth токенами
///
/// Использует HiveBoxManager для безопасного хранения токенов.
/// Все операции возвращают AsyncResult для обработки ошибок.
class TokenService implements OAuth2TokenStorage {
  static const String _boxName = 'oauth_tokens';
  static const String _logTag = 'TokenService';

  final HiveBoxManager _hiveManager;
  Box<Map<dynamic, dynamic>>? _box;

  TokenService(this._hiveManager);

  /// Инициализация сервиса (открытие бокса)
  AsyncResultDart<void, TokenServiceError> initialize() async {
    try {
      logInfo('Initializing TokenService', tag: _logTag);
      _box = await _hiveManager.openBox<Map<dynamic, dynamic>>(_boxName);
      logInfo('TokenService initialized successfully', tag: _logTag);
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to initialize TokenService: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Не удалось инициализировать хранилище токенов',
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
        'TokenService not initialized. Call initialize() first.',
      );
    }
  }

  /// Получить токен по ID
  AsyncResultDart<TokenOAuth, TokenServiceError> getToken(String id) async {
    try {
      _ensureInitialized();

      final data = _box!.get(id);
      if (data == null) {
        logWarning('Token not found: $id', tag: _logTag);
        return Failure(
          TokenServiceError.tokenNotFound(
            message: 'Токен не найден',
            data: {'id': id},
            timestamp: DateTime.now(),
          ),
        );
      }

      final token = TokenOAuth.fromJson(Map<String, dynamic>.from(data));
      logInfo(
        'Token retrieved',
        data: {'id': id, 'provider': token.provider},
        tag: _logTag,
      );
      return Success(token);
    } catch (e, stackTrace) {
      logError('Failed to get token: $e', stackTrace: stackTrace, tag: _logTag);
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при получении токена',
          data: {'id': id, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Получить все токены
  AsyncResultDart<List<TokenOAuth>, TokenServiceError> getAllTokens() async {
    try {
      _ensureInitialized();

      final tokens = <TokenOAuth>[];
      for (final key in _box!.keys) {
        final data = _box!.get(key);
        if (data != null) {
          try {
            final token = TokenOAuth.fromJson(Map<String, dynamic>.from(data));
            tokens.add(token);
          } catch (e) {
            logWarning('Failed to parse token: $key, error: $e', tag: _logTag);
          }
        }
      }

      logInfo('Retrieved ${tokens.length} tokens', tag: _logTag);
      return Success(tokens);
    } catch (e, stackTrace) {
      logError(
        'Failed to get all tokens: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при получении всех токенов',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Получить токены по провайдеру
  AsyncResultDart<List<TokenOAuth>, TokenServiceError> getTokensByProvider(
    String provider,
  ) async {
    try {
      _ensureInitialized();

      final tokens = <TokenOAuth>[];
      for (final key in _box!.keys) {
        final data = _box!.get(key);
        if (data != null) {
          try {
            final token = TokenOAuth.fromJson(Map<String, dynamic>.from(data));
            if (token.provider == provider) {
              tokens.add(token);
            }
          } catch (e) {
            logWarning('Failed to parse token: $key, error: $e', tag: _logTag);
          }
        }
      }

      logInfo(
        'Retrieved ${tokens.length} tokens for provider: $provider',
        tag: _logTag,
      );
      return Success(tokens);
    } catch (e, stackTrace) {
      logError(
        'Failed to get tokens by provider: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при получении токенов по провайдеру',
          data: {'provider': provider, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Получить токены, требующие обновления
  AsyncResultDart<List<TokenOAuth>, TokenServiceError>
  getTokensNeedingRefresh() async {
    try {
      _ensureInitialized();

      final tokens = <TokenOAuth>[];
      for (final key in _box!.keys) {
        final data = _box!.get(key);
        if (data != null) {
          try {
            final token = TokenOAuth.fromJson(Map<String, dynamic>.from(data));
            if (token.timeToRefresh && token.canRefresh) {
              tokens.add(token);
            }
          } catch (e) {
            logWarning('Failed to parse token: $key, error: $e', tag: _logTag);
          }
        }
      }

      logInfo('Found ${tokens.length} tokens needing refresh', tag: _logTag);
      return Success(tokens);
    } catch (e, stackTrace) {
      logError(
        'Failed to get tokens needing refresh: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при получении токенов для обновления',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Получить токены, требующие повторного входа
  AsyncResultDart<List<TokenOAuth>, TokenServiceError>
  getTokensNeedingLogin() async {
    try {
      _ensureInitialized();

      final tokens = <TokenOAuth>[];
      for (final key in _box!.keys) {
        final data = _box!.get(key);
        if (data != null) {
          try {
            final token = TokenOAuth.fromJson(Map<String, dynamic>.from(data));
            if (token.timeToLogin) {
              tokens.add(token);
            }
          } catch (e) {
            logWarning('Failed to parse token: $key, error: $e', tag: _logTag);
          }
        }
      }

      logInfo('Found ${tokens.length} tokens needing login', tag: _logTag);
      return Success(tokens);
    } catch (e, stackTrace) {
      logError(
        'Failed to get tokens needing login: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при получении токенов для повторного входа',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Сохранить токен (создать или обновить)
  AsyncResultDart<void, TokenServiceError> saveToken(TokenOAuth token) async {
    try {
      _ensureInitialized();

      final data = token.toJson();
      await _box!.put(token.id, data);

      logInfo(
        'Token saved',
        data: {'id': token.id, 'provider': token.provider},
        tag: _logTag,
      );
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to save token: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при сохранении токена',
          data: {'id': token.id, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Создать новый токен
  /// Проверяет, что токен с таким ID не существует
  AsyncResultDart<void, TokenServiceError> createToken(TokenOAuth token) async {
    try {
      _ensureInitialized();

      // Проверяем, существует ли уже токен с таким ID
      if (_box!.containsKey(token.id)) {
        logWarning('Token already exists: ${token.id}', tag: _logTag);
        return Failure(
          TokenServiceError.tokenAlreadyExists(
            message: 'Токен с таким ID уже существует',
            data: {'id': token.id},
            timestamp: DateTime.now(),
          ),
        );
      }

      return saveToken(token);
    } catch (e, stackTrace) {
      logError(
        'Failed to create token: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при создании токена',
          data: {'id': token.id, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Обновить существующий токен
  /// Проверяет, что токен с таким ID существует
  AsyncResultDart<void, TokenServiceError> updateToken(TokenOAuth token) async {
    try {
      _ensureInitialized();

      // Проверяем, существует ли токен
      if (!_box!.containsKey(token.id)) {
        logWarning('Token not found for update: ${token.id}', tag: _logTag);
        return Failure(
          TokenServiceError.tokenNotFound(
            message: 'Токен не найден для обновления',
            data: {'id': token.id},
            timestamp: DateTime.now(),
          ),
        );
      }

      return saveToken(token);
    } catch (e, stackTrace) {
      logError(
        'Failed to update token: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при обновлении токена',
          data: {'id': token.id, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Удалить токен
  AsyncResultDart<void, TokenServiceError> deleteToken(String id) async {
    try {
      _ensureInitialized();

      if (!_box!.containsKey(id)) {
        logWarning('Token not found for deletion: $id', tag: _logTag);
        return Failure(
          TokenServiceError.tokenNotFound(
            message: 'Токен не найден',
            data: {'id': id},
            timestamp: DateTime.now(),
          ),
        );
      }

      await _box!.delete(id);
      logInfo('Token deleted', data: {'id': id}, tag: _logTag);
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to delete token: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при удалении токена',
          data: {'id': id, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Удалить несколько токенов
  AsyncResultDart<void, TokenServiceError> deleteTokens(
    List<String> ids,
  ) async {
    try {
      _ensureInitialized();

      await _box!.deleteAll(ids);
      logInfo('Deleted ${ids.length} tokens', tag: _logTag);
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to delete tokens: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при удалении токенов',
          data: {'count': ids.length, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Удалить все токены провайдера
  AsyncResultDart<void, TokenServiceError> deleteTokensByProvider(
    String provider,
  ) async {
    try {
      _ensureInitialized();

      final tokensResult = await getTokensByProvider(provider);
      if (tokensResult.isError()) {
        return Failure(tokensResult.exceptionOrNull()!);
      }

      final tokens = tokensResult.getOrThrow();
      final ids = tokens.map((t) => t.id).toList();

      if (ids.isEmpty) {
        logInfo('No tokens found for provider: $provider', tag: _logTag);
        return const Success(unit);
      }

      return deleteTokens(ids);
    } catch (e, stackTrace) {
      logError(
        'Failed to delete tokens by provider: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при удалении токенов провайдера',
          data: {'provider': provider, 'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Очистить все токены
  AsyncResultDart<void, TokenServiceError> clearAll() async {
    try {
      _ensureInitialized();

      final count = _box!.length;
      await _box!.clear();
      logInfo('Cleared all tokens (count: $count)', tag: _logTag);
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to clear all tokens: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при очистке всех токенов',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Проверить, существует ли токен
  bool tokenExists(String id) {
    _ensureInitialized();
    return _box!.containsKey(id);
  }

  /// Получить количество токенов
  int getCount() {
    _ensureInitialized();
    return _box!.length;
  }

  /// Получить количество токенов по провайдеру
  AsyncResultDart<int, TokenServiceError> getCountByProvider(
    String provider,
  ) async {
    final result = await getTokensByProvider(provider);
    return result.map((tokens) => tokens.length);
  }

  /// Подписка на изменения токенов
  Stream<BoxEvent> watchChanges({String? tokenId}) {
    _ensureInitialized();
    return _box!.watch(key: tokenId);
  }

  /// Экспортировать все токены
  AsyncResultDart<Map<String, TokenOAuth>, TokenServiceError>
  exportAll() async {
    try {
      _ensureInitialized();

      final result = <String, TokenOAuth>{};
      for (final key in _box!.keys) {
        final data = _box!.get(key);
        if (data != null) {
          try {
            final token = TokenOAuth.fromJson(Map<String, dynamic>.from(data));
            result[key.toString()] = token;
          } catch (e) {
            logWarning('Failed to export token: $key, error: $e', tag: _logTag);
          }
        }
      }

      logInfo('Exported tokens', data: {'count': result.length}, tag: _logTag);
      return Success(result);
    } catch (e, stackTrace) {
      logError(
        'Failed to export tokens: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при экспорте токенов',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Импортировать токены
  AsyncResultDart<int, TokenServiceError> importAll(
    Map<String, TokenOAuth> tokens, {
    bool overwrite = false,
  }) async {
    try {
      _ensureInitialized();

      var imported = 0;
      for (final entry in tokens.entries) {
        final id = entry.key;
        final token = entry.value;

        // Пропускаем, если токен уже существует и overwrite = false
        if (!overwrite && _box!.containsKey(id)) {
          logInfo('Skipping existing token: $id', tag: _logTag);
          continue;
        }

        final data = token.toJson();
        await _box!.put(id, data);
        imported++;
      }

      logInfo(
        'Imported tokens',
        data: {'count': imported, 'total': tokens.length},
        tag: _logTag,
      );
      return Success(imported);
    } catch (e, stackTrace) {
      logError(
        'Failed to import tokens: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при импорте токенов',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Компактировать хранилище (оптимизация)
  AsyncResultDart<void, TokenServiceError> compact() async {
    try {
      _ensureInitialized();

      await _box!.compact();
      logInfo('Token storage compacted', tag: _logTag);
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to compact token storage: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при компактировании хранилища',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Закрыть сервис
  AsyncResultDart<void, TokenServiceError> close() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _hiveManager.closeBox(_boxName);
        _box = null;
        logInfo('TokenService closed', tag: _logTag);
      }
      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to close TokenService: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        TokenServiceError.storageError(
          message: 'Ошибка при закрытии сервиса',
          data: {'error': e.toString()},
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Освободить ресурсы (синхронно)
  void dispose() {
    if (_box != null && _box!.isOpen) {
      _box!.close();
      _box = null;
      logInfo('TokenService disposed', tag: _logTag);
    }
  }

  // Реализация интерфейса OAuth2TokenStorage

  @override
  Future<String?> load(String key) async {
    try {
      _ensureInitialized();

      final data = _box!.get(key);
      if (data == null) {
        return null;
      }

      final token = TokenOAuth.fromJson(Map<String, dynamic>.from(data));
      return token.tokenJson;
    } catch (e) {
      logError('Failed to load token for OAuth2TokenStorage: $e', tag: _logTag);
      return null;
    }
  }

  @override
  Future<void> save(String key, String value) async {
    try {
      _ensureInitialized();

      // Парсим JSON строку в OAuth2Token, затем конвертируем в TokenOAuth
      final oAuth2Token = OAuth2TokenF.fromJsonString(value);
      final tokenOAuth = TokenOAuth.fromOAuth2Token(
        id: key,
        token: oAuth2Token,
      );

      final data = tokenOAuth.toJson();
      await _box!.put(key, data);

      logInfo(
        'Token saved via OAuth2TokenStorage',
        data: {'key': key},
        tag: _logTag,
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to save token via OAuth2TokenStorage: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      _ensureInitialized();

      await _box!.delete(key);
      logInfo(
        'Token deleted via OAuth2TokenStorage',
        data: {'key': key},
        tag: _logTag,
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to delete token via OAuth2TokenStorage: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, String>> loadAll({String? keyPrefix}) async {
    try {
      _ensureInitialized();

      final result = <String, String>{};
      final prefix = keyPrefix ?? '';

      for (final key in _box!.keys) {
        final keyStr = key.toString();
        if (keyStr.startsWith(prefix)) {
          final data = _box!.get(key);
          if (data != null) {
            try {
              final token = TokenOAuth.fromJson(
                Map<String, dynamic>.from(data),
              );
              result[keyStr] = token.tokenJson;
            } catch (e) {
              logWarning(
                'Failed to parse token for loadAll: $keyStr, error: $e',
                tag: _logTag,
              );
            }
          }
        }
      }

      logInfo(
        'Loaded ${result.length} tokens via OAuth2TokenStorage',
        tag: _logTag,
      );
      return result;
    } catch (e, stackTrace) {
      logError(
        'Failed to load all tokens via OAuth2TokenStorage: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return {};
    }
  }
}
