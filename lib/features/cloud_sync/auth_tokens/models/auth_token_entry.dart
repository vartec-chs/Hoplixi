import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

part 'auth_token_entry.freezed.dart';
part 'auth_token_entry.g.dart';

/// Сохранённые OAuth токены для облачных провайдеров.
@freezed
sealed class AuthTokenEntry with _$AuthTokenEntry {
  const factory AuthTokenEntry({
    required String id,
    required CloudSyncProvider provider,
    required String accessToken,
    String? refreshToken,
    String? tokenType,
    DateTime? expiresAt,
    @Default(<String>[]) List<String> scopes,
    String? appCredentialId,
    String? appCredentialName,
    String? accountId,
    String? accountEmail,
    String? accountName,
    @Default(<String, dynamic>{}) Map<String, dynamic> extraData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AuthTokenEntry;

  factory AuthTokenEntry.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenEntryFromJson(json);
}

extension AuthTokenEntryX on AuthTokenEntry {
  String get displayLabel {
    if (accountEmail != null && accountEmail!.trim().isNotEmpty) {
      return accountEmail!.trim();
    }
    if (accountName != null && accountName!.trim().isNotEmpty) {
      return accountName!.trim();
    }
    if (appCredentialName != null && appCredentialName!.trim().isNotEmpty) {
      return appCredentialName!.trim();
    }
    return provider.metadata.displayName;
  }

  bool get hasRefreshToken =>
      refreshToken != null && refreshToken!.trim().isNotEmpty;

  bool get isExpired {
    final date = expiresAt;
    if (date == null) {
      return false;
    }
    return date.isBefore(DateTime.now());
  }
}
