import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

part 'app_credential_form_data.freezed.dart';
part 'app_credential_form_data.g.dart';

/// Форма редактирования credentials приложения.
@freezed
sealed class AppCredentialFormData with _$AppCredentialFormData {
  const factory AppCredentialFormData({
    @Default(CloudSyncProvider.dropbox) CloudSyncProvider provider,
    @Default('') String name,
    @Default('') String clientId,
    @Default('') String clientSecret,
  }) = _AppCredentialFormData;

  factory AppCredentialFormData.fromJson(Map<String, dynamic> json) =>
      _$AppCredentialFormDataFromJson(json);
}

/// Утилиты подготовки формы к сохранению.
extension AppCredentialFormDataX on AppCredentialFormData {
  String get trimmedName => name.trim();

  String get trimmedClientId => clientId.trim();

  String? get normalizedClientSecret {
    final value = clientSecret.trim();
    return value.isEmpty ? null : value;
  }
}
