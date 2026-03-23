import 'package:cloud_storage_all/cloud_storage_all.dart';

/// Обертка над OAuth2 провайдером, которая позволяет использовать уникальное имя.
///
/// Эта обертка решает проблему, когда несколько OAuth-приложений одного типа
/// (например, несколько Google-аккаунтов) создают провайдеры с одинаковым именем,
/// что приводит к их перезаписи в Map внутри OAuth2Account.
///
/// Использование:
/// ```dart
/// final googleProvider = Google(...);
/// final wrappedProvider = OAuthProviderWrapper(
///   name: 'google_app1',
///   provider: googleProvider,
/// );
/// ```
class OAuthProviderWrapper implements OAuth2Provider {
  /// Уникальное имя провайдера (обычно это app.id или комбинация типа и ID)
  @override
  final String name;

  /// Оригинальный провайдер, на который делегируются все вызовы
  final OAuth2Provider _delegate;

  OAuthProviderWrapper({required this.name, required OAuth2Provider provider})
    : _delegate = provider;

  @override
  String get authScheme => _delegate.authScheme;

  @override
  Future<OAuth2Token?> login({void Function(String error)? onError}) =>
      _delegate.login(onError: onError);

  @override
  Future<OAuth2Token?> refreshToken(String? refreshToken) =>
      _delegate.refreshToken(refreshToken);

  @override
  void cancelLogin() {
    _delegate.cancelLogin();
  }

  @override
  Future<Map<String, dynamic>?> getUserInfo(String accessToken) =>
      _delegate.getUserInfo(accessToken);

  @override
  Future<String?> exchangeCode(String? code) => _delegate.exchangeCode(code);
}
