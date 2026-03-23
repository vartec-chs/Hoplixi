import 'package:cloud_storage_all/cloud_storage_all.dart'
    show
        OAuth2Account,
        Google,
        Dropbox,
        Yandex,
        Microsoft,
        OAuth2Token,
        OAuth2RestClient,
        OAuth2Provider;
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/old/cloud_sync/common_models/oauth_config.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/services/auth_provider_wrapper.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/models/provider_service_errors.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/services/token_service.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/models/oauth_apps.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/services/oauth_apps_service.dart';
import 'package:result_dart/result_dart.dart';

/// Сервис для управления OAuth2 провайдерами и авторизацией
///
/// Использует OAuth2Account для управления токенами и провайдерами.
/// Регистрирует провайдеры на основе данных из OAuthAppsService.
///
/// ## Важная информация о провайдерах
///
/// Каждое OAuth-приложение получает уникальное имя провайдера на основе `app.id`,
/// что позволяет иметь несколько приложений одного типа (например, несколько
/// Google-аккаунтов) без конфликтов имен.
///
/// ## Использование
///
/// ```dart
/// // 1. Инициализация сервиса
/// final result = await providerService.initialize();
///
/// // 2. Получить список зарегистрированных провайдеров
/// final providersResult = await providerService.getRegisteredProviders();
/// final appIds = providersResult.getOrThrow(); // ['app_id_1', 'app_id_2', ...]
///
/// // 3. Выполнить вход используя app.id
/// final loginResult = await providerService.login('app_id_1');
/// final token = loginResult.getOrThrow();
///
/// // 4. Получить информацию о приложении
/// final appResult = await providerService.getAppById('app_id_1');
/// final app = appResult.getOrThrow();
/// print('Provider: ${app.name} (${app.type.name})');
/// ```
///
/// **Внимание:** Все методы, принимающие параметр `provider`, ожидают `app.id`,
/// а не тип провайдера (например, не "google", а конкретный ID приложения).
class AuthProvidersService {
  static const String _logTag = 'ProviderService';
  static const String _appPrefix = 'hoplixi';

  final OAuthAppsService _appsService;
  final TokenService _tokenService;
  late final OAuth2Account _account;
  final Map<String, OAuth2RestClient> _clients = {};
  final Map<String, OAuth2Provider> _providers = {};

  bool _initialized = false;

  AuthProvidersService({
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

      await _tokenService.initialize();

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
      final baseProvider = _createProvider(app);
      if (baseProvider == null) {
        return Failure(
          ProviderServiceError.unsupportedProvider(
            message: 'Provider type ${app.type.name} is not supported',
          ),
        );
      }

      // Оборачиваем провайдер для использования уникального имени
      // Используем app.id как уникальный идентификатор
      final uniqueProvider = OAuthProviderWrapper(
        name: app.id,
        provider: baseProvider,
      );

      _account.addProvider(uniqueProvider);

      logInfo(
        'Registered provider: ${app.name} (${app.type.identifier}) with ID: ${app.id}',
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
  OAuth2Provider? _createProvider(OauthApps app) {
    switch (app.type) {
      case OauthAppsType.google:
        return Google(
          clientId: app.clientId,
          clientSecret: app.clientSecret,
          redirectUri: OAuthConfig.redirectUri,
          scopes: OAuthConfig.googleScopes,
        );

      case OauthAppsType.onedrive:
        return Microsoft(
          clientId: app.clientId,
          clientSecret: app.clientSecret,
          redirectUri: OAuthConfig.redirectUri,
          scopes: OAuthConfig.onedriveScopes,
        );

      case OauthAppsType.dropbox:
        return Dropbox(
          clientId: app.clientId,
          clientSecret: app.clientSecret,
          redirectUri: OAuthConfig.redirectUri,
          scopes: OAuthConfig.dropboxScopes,
        );

      case OauthAppsType.yandex:
        return Yandex(
          clientId: app.clientId,
          clientSecret: app.clientSecret,
          redirectUri: OAuthConfig.redirectUri,
          scopes: OAuthConfig.yandexScopes,
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

  /// Получить список всех зарегистрированных провайдеров (app.id)
  ///
  /// Возвращает список уникальных ID OAuth-приложений,
  /// которые были успешно зарегистрированы в сервисе.
  AsyncResultDart<List<String>, ProviderServiceError>
  getRegisteredProviders() async {
    try {
      _ensureInitialized();

      // Получаем все приложения из OAuthAppsService
      final appsResult = await _appsService.getAllApps();
      if (appsResult.isError()) {
        return Failure(
          ProviderServiceError.operationFailed(
            message: 'Failed to get apps: ${appsResult.exceptionOrNull()}',
          ),
        );
      }

      final apps = appsResult.getOrThrow();
      final providerIds = apps
          .where((app) => app.type.isActive)
          .map((app) => app.id)
          .toList();

      logInfo('Found ${providerIds.length} registered providers', tag: _logTag);

      return Success(providerIds);
    } catch (e, stackTrace) {
      logError(
        'Failed to get registered providers: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.operationFailed(
          message: 'Failed to get registered providers: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Получить OAuth-приложение по его ID
  ///
  /// Полезно для получения информации о провайдере (имя, тип) по его ID.
  AsyncResultDart<OauthApps, ProviderServiceError> getAppById(
    String appId,
  ) async {
    try {
      _ensureInitialized();

      final appsResult = await _appsService.getAllApps();
      if (appsResult.isError()) {
        return Failure(
          ProviderServiceError.operationFailed(
            message: 'Failed to get apps: ${appsResult.exceptionOrNull()}',
          ),
        );
      }

      final apps = appsResult.getOrThrow();
      final app = apps.where((a) => a.id == appId).firstOrNull;

      if (app == null) {
        return Failure(
          ProviderServiceError.unsupportedProvider(
            message: 'OAuth app with ID $appId not found',
          ),
        );
      }

      return Success(app);
    } catch (e, stackTrace) {
      logError(
        'Failed to get app by ID: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.operationFailed(
          message: 'Failed to get app by ID: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Выполнить новый вход для провайдера
  ///
  /// [provider] - уникальный ID OAuth-приложения (app.id), а не тип провайдера
  /// [onError] - callback для получения ошибок в процессе авторизации
  AsyncResultDart<OAuth2Token, ProviderServiceError> login(
    String provider, {
    void Function(String error)? onError,
  }) async {
    try {
      _ensureInitialized();

      logInfo('Starting login for provider: $provider', tag: _logTag);

      final token = await _account.newLogin(provider, onError: onError);

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
  ///
  /// [provider] - уникальный ID OAuth-приложения (app.id), а не тип провайдера
  /// [userName] - имя пользователя для входа
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
  ///
  /// [service] - фильтр по ID OAuth-приложения (app.id).
  /// Если пусто, возвращаются все аккаунты.
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
  ///
  /// [service] - ID OAuth-приложения (app.id)
  /// [userName] - имя пользователя
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
  ///
  /// [service] - ID OAuth-приложения (app.id)
  /// [userName] - имя пользователя
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
  ///
  /// [service] - фильтр по ID OAuth-приложения (app.id).
  /// Если пусто, возвращается любой доступный токен.
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

  /// Создать или получить существующий клиент для токена
  AsyncResultDart<OAuth2RestClient, ProviderServiceError> getOrCreateClient(
    OAuth2Token token, {
    String? authScheme,
    bool forceNew = false,
  }) async {
    try {
      _ensureInitialized();

      final clientKey = '${token.provider}:${token.userName}';

      // Если клиент уже существует и не нужно создавать новый
      if (!forceNew && _clients.containsKey(clientKey)) {
        logInfo(
          'Using cached client for provider: ${token.provider}, user: ${token.userName}',
          tag: _logTag,
        );
        return Success(_clients[clientKey]!);
      }

      // Создаем новый клиент
      logInfo(
        'Creating new client for provider: ${token.provider}, user: ${token.userName}',
        tag: _logTag,
      );

      final client = await _account.createClient(token, authScheme: authScheme);

      // Сохраняем в кэше
      _clients[clientKey] = client;

      logInfo(
        'Client created and cached for provider: ${token.provider}, user: ${token.userName}',
        tag: _logTag,
      );

      return Success(client);
    } catch (e, stackTrace) {
      logError(
        'Failed to create client: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.operationFailed(
          message: 'Failed to create client: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Удалить клиент из кэша
  ///
  /// [provider] - ID OAuth-приложения (app.id)
  /// [userName] - имя пользователя
  AsyncResultDart<void, ProviderServiceError> removeClient(
    String provider,
    String userName,
  ) async {
    try {
      _ensureInitialized();

      final clientKey = '$provider:$userName';
      _clients.remove(clientKey);

      logInfo(
        'Removed client from cache for provider: $provider, user: $userName',
        tag: _logTag,
      );

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to remove client: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.operationFailed(
          message: 'Failed to remove client: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Очистить все клиенты из кэша
  AsyncResultDart<void, ProviderServiceError> clearAllClients() async {
    try {
      _ensureInitialized();

      final count = _clients.length;
      _clients.clear();

      logInfo('Cleared $count clients from cache', tag: _logTag);

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to clear clients: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.operationFailed(
          message: 'Failed to clear clients: ${e.toString()}',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Получить количество кэшированных клиентов
  int get cachedClientsCount {
    return _clients.length;
  }

  /// Отменить текущий процесс авторизации для провайдера
  ///
  /// [provider] - ID OAuth-приложения (app.id)
  AsyncResultDart<void, ProviderServiceError> cancelLogin(
    String provider,
  ) async {
    try {
      _ensureInitialized();

      final oauthProvider = _providers[provider];
      if (oauthProvider == null) {
        return Failure(
          ProviderServiceError.providerNotFound(
            provider: provider,
            message: 'Provider not registered',
          ),
        );
      }

      logInfo('Cancelling login for provider: $provider', tag: _logTag);
      oauthProvider.cancelLogin();

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to cancel login: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        ProviderServiceError.unknown(
          message: 'Failed to cancel login: $e',
          data: {'error': e.toString()},
        ),
      );
    }
  }
}
