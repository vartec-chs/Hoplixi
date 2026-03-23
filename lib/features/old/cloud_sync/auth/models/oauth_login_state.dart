import 'package:cloud_storage_all/cloud_storage_all.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/models/oauth_apps.dart';

part 'oauth_login_state.freezed.dart';

/// Состояние процесса OAuth авторизации
@freezed
sealed class OAuthLoginState with _$OAuthLoginState {
  const factory OAuthLoginState({
    /// Список доступных OAuth приложений
    @Default([]) List<OauthApps> availableApps,

    /// Текущий выбранный провайдер (app.id)
    String? selectedProviderId,

    /// Информация о выбранном приложении
    OauthApps? selectedApp,

    /// Состояние процесса авторизации
    @Default(LoginStatus.idle) LoginStatus loginStatus,

    /// Полученный токен после успешной авторизации
    OAuth2Token? token,

    /// Сообщение об ошибке
    String? errorMessage,

    /// Список ошибок, возникших в процессе авторизации
    @Default([]) List<String> authErrors,

    /// Список сохраненных аккаунтов для выбранного провайдера
    @Default([]) List<SavedAccount> savedAccounts,
  }) = _OAuthLoginState;
}

/// Статус процесса авторизации
enum LoginStatus {
  /// Начальное состояние
  idle,

  /// Загрузка списка провайдеров
  loadingProviders,

  /// Попытка автоматического входа
  autoLogin,

  /// Выполнение нового входа
  loggingIn,

  /// Успешная авторизация
  success,

  /// Ошибка авторизации
  error,
}

/// Сохраненный аккаунт для провайдера
@freezed
sealed class SavedAccount with _$SavedAccount {
  const factory SavedAccount({
    required String providerId,
    required String userName,
  }) = _SavedAccount;
}
