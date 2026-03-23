import 'package:freezed_annotation/freezed_annotation.dart';

part 'cloud_sync_oauth_result.freezed.dart';
part 'cloud_sync_oauth_result.g.dart';

@freezed
sealed class CloudSyncOAuthResult with _$CloudSyncOAuthResult {
  const factory CloudSyncOAuthResult({
    required String accessToken,
    String? refreshToken,
    String? tokenType,
    DateTime? expiresAt,
    @Default(<String>[]) List<String> scopes,
    String? accountId,
    String? accountEmail,
    String? accountName,
    @Default(<String, dynamic>{}) Map<String, dynamic> extraData,
  }) = _CloudSyncOAuthResult;

  factory CloudSyncOAuthResult.fromJson(Map<String, dynamic> json) =>
      _$CloudSyncOAuthResultFromJson(json);
}
