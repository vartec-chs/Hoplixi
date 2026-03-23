import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_storage_all/cloud_storage_all.dart'
    show OAuth2Token, OAuth2TokenF;

part 'token_oauth.freezed.dart';
part 'token_oauth.g.dart';

@freezed
abstract class TokenOAuth with _$TokenOAuth {
  const TokenOAuth._();

  const factory TokenOAuth({
    required String id,
    required String accessToken,
    required String refreshToken,
    required String userName,
    required String iss,
    required String provider,
    required bool timeToRefresh,
    required bool canRefresh,
    required bool timeToLogin,
    required String tokenJson,
  }) = _TokenOAuth;

  /// Создает [TokenOAuth] из [OAuth2Token]
  factory TokenOAuth.fromOAuth2Token({
    required String id,
    required OAuth2Token token,
  }) {
    return TokenOAuth(
      id: id,
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      userName: token.userName,
      iss: token.iss,
      provider: token.provider,
      timeToRefresh: token.timeToRefresh,
      canRefresh: token.canRefresh,
      timeToLogin: token.timeToLogin,
      tokenJson: token.toJsonString(),
    );
  }

  /// Конвертирует [TokenOAuth] в [OAuth2Token]
  OAuth2Token toOAuth2Token() {
    return OAuth2TokenF.fromJsonString(tokenJson);
  }

  factory TokenOAuth.fromJson(Map<String, dynamic> json) =>
      _$TokenOAuthFromJson(json);
}
