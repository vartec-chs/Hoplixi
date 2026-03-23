import 'package:freezed_annotation/freezed_annotation.dart';

part 'cloud_sync_auth_error.freezed.dart';
part 'cloud_sync_auth_error.g.dart';

@freezed
sealed class CloudSyncAuthError with _$CloudSyncAuthError {
  const factory CloudSyncAuthError.cancelled({String? message}) =
      _CloudSyncAuthCancelledError;

  const factory CloudSyncAuthError.unsupportedCredential({String? message}) =
      _CloudSyncAuthUnsupportedCredentialError;

  const factory CloudSyncAuthError.misconfiguredRedirect({String? message}) =
      _CloudSyncAuthMisconfiguredRedirectError;

  const factory CloudSyncAuthError.oauthProvider({String? message}) =
      _CloudSyncAuthOAuthProviderError;

  const factory CloudSyncAuthError.network({String? message}) =
      _CloudSyncAuthNetworkError;

  const factory CloudSyncAuthError.timeout({String? message}) =
      _CloudSyncAuthTimeoutError;

  const factory CloudSyncAuthError.unknown({String? message}) =
      _CloudSyncAuthUnknownError;

  factory CloudSyncAuthError.fromJson(Map<String, dynamic> json) =>
      _$CloudSyncAuthErrorFromJson(json);
}
