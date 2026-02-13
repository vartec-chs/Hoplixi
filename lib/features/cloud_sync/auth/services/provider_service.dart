import 'package:cloud_storage_all/cloud_storage_all.dart'
    show OAuth2Account, Google, Dropbox, Yandex, Microsoft, OAuth2Token;
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/provider_service_errors.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/token_service.dart';
import 'package:hoplixi/features/cloud_sync/oauth_apps/models/oauth_apps.dart';
import 'package:hoplixi/features/cloud_sync/oauth_apps/services/oauth_apps_service.dart';
import 'package:result_dart/result_dart.dart';

/// Сервис для управления OAuth2 провайдерами и авторизацией
///
/// Использует OAuth2Account для управления токенами и провайдерами.
/// Регистрирует провайдеры на основе данных из OAuthAppsService.
class ProviderService {
  static const String _logTag = 'ProviderService';
  static const String _appPrefix = 'hoplixi';

  final OAuthAppsService _appsService;
  final TokenService _tokenService;
  late final OAuth2Account _account;

  bool _initialized = false;

  ProviderService({
    required OAuthAppsService appsService,
    required TokenService tokenService,
  }) : _appsService = appsService,
       _tokenService = tokenService;

  /// Инициализация сервиса
  AsyncResultDart<void, ProviderServiceError> initialize() async {
    try {
      if (_initialized) {
        logInfo('ProviderService already initialized', tag: _logTag);
        return const Success(unit);
      }

      // Создаем OAuth2Account с TokenService как хранилищем
      _account = OAuth2Account(
        tokenStorage: _tokenService,
        appPrefix: _appPrefix,
      );

      // Регистрируем все активные провайдеры
      final appsResult = await _appsService.getAllApps();
      if (appsResult.isError()) {
        return Failure(
          ProviderServiceError.initializationFailed(
            message:
                'Failed to load OAuth apps: ${appsResult.exceptionOrNull()}',
          ),
        );
      }

      final apps = appsResult.getOrThrow();
      int registeredCount = 0;

      for (final app in apps) {
        if (app.type.isActive) {
          final result = await _registerProvider(app);
          if (result.isSuccess()) {
            registeredCount++;
          } else {
            logWarning(
              'Failed to register provider: ${app.name}',
              tag: _logTag,
            );
          }
        }
      }

      _initialized = true;
      logInfo(
        'ProviderService initialized with $registeredCount providers',
        tag: _logTag,
      );

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to initialize ProviderService: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.initializationFailed(
          message: e.toString(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Зарегистрировать провайдер на основе OAuth приложения
  AsyncResultDart<void, ProviderServiceError> _registerProvider(
    OauthApps app,
  ) async {
    try {
      final provider = _createProvider(app);
      if (provider == null) {
        return Failure(
          ProviderServiceError.unsupportedProvider(
            message: 'Provider type ${app.type.name} is not supported',
          ),
        );
      }

      _account.addProvider(provider);

      logInfo(
        'Registered provider: ${app.name} (${app.type.identifier})',
        tag: _logTag,
      );

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to register provider ${app.name}: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.registrationFailed(
          message: 'Failed to register provider: ${app.name}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Создать провайдер на основе типа приложения
  dynamic _createProvider(OauthApps app) {
    switch (app.type) {
      case OauthAppsType.google:
        return Google(
          clientId: app.clientId,
          clientSecret: app.clientSecret,
          redirectUri: 'http://localhost:8080/callback',
          scopes: [
            'https://www.googleapis.com/auth/drive.file',
            'https://www.googleapis.com/auth/userinfo.profile',
          ],
        );

      case OauthAppsType.onedrive:
        return Microsoft(
          clientId: app.clientId,
          clientSecret: app.clientSecret,
          redirectUri: 'http://localhost:8080/callback',
          scopes: ['Files.ReadWrite.All', 'User.Read'],
        );

      case OauthAppsType.dropbox:
        return Dropbox(
          clientId: app.clientId,
          clientSecret: app.clientSecret,
          redirectUri: 'http://localhost:8080/callback',
          scopes: [
            'files.metadata.read',
            'files.content.read',
            'files.content.write',
          ],
        );

      case OauthAppsType.yandex:
        return Yandex(
          clientId: app.clientId,
          clientSecret: app.clientSecret,
          redirectUri: 'http://localhost:8080/callback',
          scopes: ['login:info', 'disk:info', 'disk:read', 'disk:write'],
        );

      case OauthAppsType.other:
        return null;
    }
  }

  /// Проверка инициализации
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('ProviderService is not initialized');
    }
  }

  /// Выполнить новый вход для провайдера
  AsyncResultDart<OAuth2Token, ProviderServiceError> login(
    String provider,
  ) async {
    try {
      _ensureInitialized();

      logInfo('Starting login for provider: $provider', tag: _logTag);

      final token = await _account.newLogin(provider);
      if (token == null) {
        return Failure(
          ProviderServiceError.loginFailed(
            message: 'Login failed for provider: $provider',
          ),
        );
      }

      logInfo(
        'Login successful for provider: $provider, user: ${token.userName}',
        tag: _logTag,
      );

      return Success(token);
    } catch (e, stackTrace) {
      logError(
        'Login failed for provider $provider: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.loginFailed(
          message: 'Login failed: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Попытка автоматического входа
  AsyncResultDart<OAuth2Token, ProviderServiceError> tryAutoLogin(
    String provider,
    String userName,
  ) async {
    try {
      _ensureInitialized();

      logInfo(
        'Trying auto login for provider: $provider, user: $userName',
        tag: _logTag,
      );

      final token = await _account.tryAutoLogin(provider, userName);

      if (token != null) {
        logInfo(
          'Auto login successful for provider: $provider, user: $userName',
          tag: _logTag,
        );
        return Success(token);
      } else {
        logInfo(
          'No saved token found for provider: $provider, user: $userName',
          tag: _logTag,
        );
        return Failure(
          ProviderServiceError.noTokenFound(
            message: 'No token found for provider: $provider, user: $userName',
          ),
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Auto login failed for provider $provider, user $userName: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.autoLoginFailed(
          message: 'Auto login failed: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Принудительный повторный вход
  AsyncResultDart<OAuth2Token, ProviderServiceError> forceRelogin(
    OAuth2Token expiredToken,
  ) async {
    try {
      _ensureInitialized();

      logInfo(
        'Force relogin for provider: ${expiredToken.provider}, user: ${expiredToken.userName}',
        tag: _logTag,
      );

      final token = await _account.forceRelogin(expiredToken);

      if (token != null) {
        logInfo(
          'Force relogin successful for provider: ${expiredToken.provider}',
          tag: _logTag,
        );
        return Success(token);
      } else {
        logInfo(
          'Force relogin failed, no token returned for provider: ${expiredToken.provider}',
          tag: _logTag,
        );
        return Failure(
          ProviderServiceError.noTokenFound(
            message:
                'Force relogin failed, no token returned for provider: ${expiredToken.provider}',
          ),
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Force relogin failed: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.reloginFailed(
          message: 'Force relogin failed: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Обновить токен
  AsyncResultDart<OAuth2Token, ProviderServiceError> refreshToken(
    OAuth2Token expiredToken,
  ) async {
    try {
      _ensureInitialized();

      logInfo(
        'Refreshing token for provider: ${expiredToken.provider}, user: ${expiredToken.userName}',
        tag: _logTag,
      );

      final token = await _account.refreshToken(expiredToken);

      if (token != null) {
        logInfo(
          'Token refreshed successfully for provider: ${expiredToken.provider}',
          tag: _logTag,
        );
        return Success(token);
      } else {
        logInfo(
          'Token refresh failed, no token returned for provider: ${expiredToken.provider}',
          tag: _logTag,
        );
        return Failure(
          ProviderServiceError.noTokenFound(
            message:
                'Token refresh failed, no token returned for provider: ${expiredToken.provider}',
          ),
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Token refresh failed: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.refreshFailed(
          message: 'Token refresh failed: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Получить все аккаунты
  AsyncResultDart<List<(String, String)>, ProviderServiceError> getAllAccounts({
    String service = '',
  }) async {
    try {
      _ensureInitialized();

      final accounts = await _account.allAccounts(service: service);

      logInfo(
        'Retrieved ${accounts.length} accounts for service: ${service.isEmpty ? "all" : service}',
        tag: _logTag,
      );

      return Success(accounts);
    } catch (e, stackTrace) {
      logError(
        'Failed to get accounts: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.operationFailed(
          message: 'Failed to get accounts: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Загрузить аккаунт
  AsyncResultDart<OAuth2Token, ProviderServiceError> loadAccount(
    String service,
    String userName,
  ) async {
    try {
      _ensureInitialized();

      final token = await _account.loadAccount(service, userName);

      if (token != null) {
        logInfo(
          'Loaded account for service: $service, user: $userName',
          tag: _logTag,
        );
        return Success(token);
      } else {
        logInfo(
          'No account found for service: $service, user: $userName',
          tag: _logTag,
        );
        return Failure(
          ProviderServiceError.noTokenFound(
            message: 'No account found for service: $service, user: $userName',
          ),
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to load account: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.operationFailed(
          message: 'Failed to load account: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Удалить аккаунт
  AsyncResultDart<void, ProviderServiceError> deleteAccount(
    String service,
    String userName,
  ) async {
    try {
      _ensureInitialized();

      await _account.deleteAccount(service, userName);

      logInfo(
        'Deleted account for service: $service, user: $userName',
        tag: _logTag,
      );

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to delete account: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.operationFailed(
          message: 'Failed to delete account: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Получить любой доступный токен для сервиса
  AsyncResultDart<OAuth2Token, ProviderServiceError> getAnyToken({
    String service = '',
  }) async {
    try {
      _ensureInitialized();

      final token = await _account.any(service: service);

      if (token != null) {
        logInfo(
          'Found token for service: ${service.isEmpty ? "any" : service}',
          tag: _logTag,
        );
        return Success(token);
      } else {
        logInfo(
          'No tokens found for service: ${service.isEmpty ? "any" : service}',
          tag: _logTag,
        );
        return Failure(
          ProviderServiceError.noTokenFound(
            message:
                'No tokens found for service: ${service.isEmpty ? "any" : service}',
          ),
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to get any token: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.operationFailed(
          message: 'Failed to get any token: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Перезагрузить провайдеры (полезно после изменения OAuth приложений)
  AsyncResultDart<void, ProviderServiceError> reloadProviders() async {
    try {
      _ensureInitialized();

      logInfo('Reloading providers', tag: _logTag);

      // Получаем все приложения
      final appsResult = await _appsService.getAllApps();
      if (appsResult.isError()) {
        return Failure(
          ProviderServiceError.operationFailed(
            message:
                'Failed to load OAuth apps: ${appsResult.exceptionOrNull()}',
          ),
        );
      }

      final apps = appsResult.getOrThrow();
      int registeredCount = 0;

      // Регистрируем провайдеры заново
      for (final app in apps) {
        if (app.type.isActive) {
          final result = await _registerProvider(app);
          if (result.isSuccess()) {
            registeredCount++;
          }
        }
      }

      logInfo('Reloaded $registeredCount providers', tag: _logTag);

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to reload providers: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.operationFailed(
          message: 'Failed to reload providers: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Получить OAuth2Account для прямого доступа (если нужно)
  OAuth2Account get account {
    _ensureInitialized();
    return _account;
  }
}
