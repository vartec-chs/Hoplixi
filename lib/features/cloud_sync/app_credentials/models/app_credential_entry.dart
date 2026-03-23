import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

part 'app_credential_entry.freezed.dart';
part 'app_credential_entry.g.dart';

/// Запись credentials приложения для OAuth-авторизации.
@freezed
sealed class AppCredentialEntry with _$AppCredentialEntry {
  const factory AppCredentialEntry({
    required String id,
    required CloudSyncProvider provider,
    required String name,
    required String clientId,
    String? clientSecret,
    @Default(false) bool isBuiltin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AppCredentialEntry;

  factory AppCredentialEntry.fromJson(Map<String, dynamic> json) =>
      _$AppCredentialEntryFromJson(json);
}
