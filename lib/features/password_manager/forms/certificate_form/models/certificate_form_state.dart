import 'package:freezed_annotation/freezed_annotation.dart';

part 'certificate_form_state.freezed.dart';

@freezed
sealed class CertificateFormState with _$CertificateFormState {
  const factory CertificateFormState({
    @Default(false) bool isEditMode,
    String? editingCertificateId,
    @Default('') String name,
    @Default('') String certificatePem,
    @Default('') String privateKey,
    @Default('') String serialNumber,
    @Default('') String issuer,
    @Default('') String subject,
    @Default('') String fingerprint,
    @Default('') String ocspUrl,
    @Default('') String crlUrl,
    @Default('') String description,
    @Default(false) bool autoRenew,
    String? noteId,
    String? noteName,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    String? nameError,
    String? certificatePemError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _CertificateFormState;

  const CertificateFormState._();
}
