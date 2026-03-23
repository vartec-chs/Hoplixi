import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/models/oauth_login_state.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/providers/auth_provider.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/services/auth_providers_service.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/models/oauth_apps.dart';

/// AsyncNotifier для управления процессом OAuth авторизации
class AuthLoginNotifier extends AsyncNotifier<OAuthLoginState> {
  static const String _logTag = 'AuthLoginNotifier';

  late final AuthProvidersService _service;
  int _operationId = 0; // Счетчик операций

  @override
  Future<OAuthLoginState> build() async {
    // Получаем инициализированный сервис
    final serviceAsync = await ref.watch(
      authProvidersServiceAsyncProvider.future,
    );
    _service = serviceAsync;

    // Загружаем список доступных провайдеров
    return _loadProviders();
  }

  /// Загрузить список доступных провайдеров
  Future<OAuthLoginState> _loadProviders() async {
    try {
      final providersResult = await _service.getRegisteredProviders();

      if (providersResult.isError()) {
        logError(
          'Failed to load providers: ${providersResult.exceptionOrNull()}',
          tag: _logTag,
        );
        return OAuthLoginState(
          loginStatus: LoginStatus.error,
          errorMessage: providersResult.exceptionOrNull()?.toString(),
        );
      }

      final providerIds = providersResult.getOrThrow();
      final apps = <OauthApps>[];

      // Получаем информацию о каждом провайдере
      for (final id in providerIds) {
        final appResult = await _service.getAppById(id);
        if (appResult.isSuccess()) {
          apps.add(appResult.getOrThrow());
        }
      }

      logInfo('Loaded ${apps.length} available providers', tag: _logTag);

      return OAuthLoginState(
        availableApps: apps,
        loginStatus: LoginStatus.idle,
      );
    } catch (e, stackTrace) {
      logError(
        'Error loading providers: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return OAuthLoginState(
        loginStatus: LoginStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Выбрать провайдера
  Future<void> selectProvider(String providerId) async {
    final currentState = state.value ?? const OAuthLoginState();

    // Находим приложение по ID
    final app = currentState.availableApps.firstWhere(
      (a) => a.id == providerId,
    );

    // Загружаем сохраненные аккаунты для этого провайдера
    final accountsResult = await _service.getAllAccounts(service: providerId);
    final savedAccounts = <SavedAccount>[];

    if (accountsResult.isSuccess()) {
      for (final (_, userName) in accountsResult.getOrThrow()) {
        savedAccounts.add(
          SavedAccount(providerId: providerId, userName: userName),
        );
      }
    }

    logInfo(
      'Selected provider: ${app.name}, found ${savedAccounts.length} saved accounts',
      tag: _logTag,
    );

    state = AsyncData(
      currentState.copyWith(
        selectedProviderId: providerId,
        selectedApp: app,
        savedAccounts: savedAccounts,
        loginStatus: LoginStatus.idle,
        errorMessage: null,
      ),
    );
  }

  /// Попробовать автоматический вход с сохраненным аккаунтом
  Future<void> tryAutoLogin(String userName) async {
    final currentState = state.value ?? const OAuthLoginState();

    if (currentState.selectedProviderId == null) {
      logWarning('No provider selected for auto login', tag: _logTag);
      return;
    }

    final currentOperationId =
        ++_operationId; // Уникальный ID для этой операции

    state = AsyncData(
      currentState.copyWith(
        loginStatus: LoginStatus.autoLogin,
        errorMessage: null,
      ),
    );

    try {
      final result = await _service.tryAutoLogin(
        currentState.selectedProviderId!,
        userName,
      );

      // Проверяем, не была ли отменена/заменена операция
      if (currentOperationId != _operationId) {
        logInfo('Auto login was cancelled or replaced by user', tag: _logTag);
        return;
      }

      if (result.isSuccess()) {
        final token = result.getOrThrow();

        logInfo(
          'Auto login successful for ${currentState.selectedApp?.name}',
          tag: _logTag,
        );

        state = AsyncData(
          currentState.copyWith(
            loginStatus: LoginStatus.success,
            token: token,
            errorMessage: null,
          ),
        );
      } else {
        logWarning(
          'Auto login failed: ${result.exceptionOrNull()}',
          tag: _logTag,
        );

        // Если авто-вход не удался, предлагаем новый вход
        state = AsyncData(
          currentState.copyWith(
            loginStatus: LoginStatus.idle,
            errorMessage: 'Требуется повторная авторизация',
          ),
        );
      }
    } catch (e, stackTrace) {
      // Проверяем, не была ли отменена/заменена операция
      if (currentOperationId != _operationId) {
        logInfo(
          'Auto login was cancelled or replaced during error',
          tag: _logTag,
        );
        return;
      }
      logError('Auto login error: $e', stackTrace: stackTrace, tag: _logTag);

      state = AsyncData(
        currentState.copyWith(
          loginStatus: LoginStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Добавить ошибку авторизации в список
  void _addAuthError(String error) {
    final currentState = state.value ?? const OAuthLoginState();
    final updatedErrors = [...currentState.authErrors, error];

    state = AsyncData(currentState.copyWith(authErrors: updatedErrors));

    logWarning('Auth error: $error', tag: _logTag);
  }

  /// Выполнить новый вход
  Future<void> login() async {
    final currentState = state.value ?? const OAuthLoginState();

    if (currentState.selectedProviderId == null) {
      logWarning('No provider selected for login', tag: _logTag);
      return;
    }

    final currentOperationId =
        ++_operationId; // Уникальный ID для этой операции

    state = AsyncData(
      currentState.copyWith(
        loginStatus: LoginStatus.loggingIn,
        errorMessage: null,
        authErrors: [], // Очищаем предыдущие ошибки
      ),
    );

    try {
      final result = await _service.login(
        currentState.selectedProviderId!,
        onError: (error) {
          // Добавляем ошибку только если операция не отменена
          if (currentOperationId == _operationId) {
            _addAuthError(error);
          }
        },
      );

      // Проверяем, не была ли отменена/заменена операция
      if (currentOperationId != _operationId) {
        logInfo('Login was cancelled or replaced by user', tag: _logTag);
        return;
      }

      if (result.isSuccess()) {
        final token = result.getOrThrow();

        logInfo(
          'Login successful for ${currentState.selectedApp?.name}, user: ${token.userName}',
          tag: _logTag,
        );

        state = AsyncData(
          currentState.copyWith(
            loginStatus: LoginStatus.success,
            token: token,
            errorMessage: null,
          ),
        );
      } else {
        final error = result.exceptionOrNull();

        logError('Login failed: $error', tag: _logTag);

        state = AsyncData(
          currentState.copyWith(
            loginStatus: LoginStatus.error,
            errorMessage: error?.toString() ?? 'Ошибка авторизации',
          ),
        );
      }
    } catch (e, stackTrace) {
      // Проверяем, не была ли отменена/заменена операция
      if (currentOperationId != _operationId) {
        logInfo('Login was cancelled or replaced during error', tag: _logTag);
        return;
      }

      logError('Login error: $e', stackTrace: stackTrace, tag: _logTag);

      state = AsyncData(
        currentState.copyWith(
          loginStatus: LoginStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Отменить текущий процесс авторизации
  Future<void> cancel() async {
    final currentState = state.value ?? const OAuthLoginState();

    // Отменяем только если идет процесс авторизации или авто-входа
    if (currentState.loginStatus == LoginStatus.loggingIn ||
        currentState.loginStatus == LoginStatus.autoLogin) {
      _operationId++; // Увеличиваем счетчик - текущая операция станет недействительной

      // Вызываем отмену на уровне сервиса
      if (currentState.selectedProviderId != null) {
        await _service.cancelLogin(currentState.selectedProviderId!);
      }

      state = AsyncData(
        currentState.copyWith(
          loginStatus: LoginStatus.idle,
          errorMessage: null,
          authErrors: [], // Очищаем ошибки при отмене
        ),
      );

      logInfo('Cancelled login process', tag: _logTag);
    }
  }

  /// Сбросить состояние к выбору провайдера
  void reset() {
    final currentState = state.value ?? const OAuthLoginState();

    state = AsyncData(
      currentState.copyWith(
        selectedProviderId: null,
        selectedApp: null,
        savedAccounts: [],
        loginStatus: LoginStatus.idle,
        token: null,
        errorMessage: null,
        authErrors: [],
      ),
    );

    logInfo('Reset login state', tag: _logTag);
  }

  /// Перезагрузить список провайдеров
  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadProviders());
  }
}

/// Provider для управления OAuth авторизацией
final authLoginProvider =
    AsyncNotifierProvider<AuthLoginNotifier, OAuthLoginState>(
      AuthLoginNotifier.new,
    );
