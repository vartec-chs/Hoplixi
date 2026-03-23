import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';

part 'auth_credential_option.freezed.dart';
part 'auth_credential_option.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum AuthCredentialSupportIssue {
  unsupportedProvider,
  missingProviderConfig,
  mobileDropboxRequiresBuiltin,
  mobilePlatformUnsupported,
}

@freezed
sealed class AuthCredentialOption with _$AuthCredentialOption {
  const factory AuthCredentialOption({
    required AppCredentialEntry entry,
    @Default(true) bool isSupported,
    AuthCredentialSupportIssue? supportIssue,
  }) = _AuthCredentialOption;

  factory AuthCredentialOption.fromJson(Map<String, dynamic> json) =>
      _$AuthCredentialOptionFromJson(json);
}
