import 'package:freezed_annotation/freezed_annotation.dart';

part 'license_key_form_state.freezed.dart';

@freezed
sealed class LicenseKeyFormState with _$LicenseKeyFormState {
  const factory LicenseKeyFormState({
    @Default(false) bool isEditMode,
    String? editingLicenseKeyId,
    @Default('') String name,
    @Default('') String product,
    @Default('') String licenseKey,
    @Default('') String licenseType,
    @Default('') String seats,
    @Default('') String maxActivations,
    @Default('') String activatedOn,
    @Default('') String purchaseDate,
    @Default('') String purchaseFrom,
    @Default('') String orderId,
    @Default('') String licenseFileId,
    @Default('') String expiresAt,
    @Default('') String licenseNotes,
    @Default('') String supportContact,
    @Default('') String description,
    String? noteId,
    String? noteName,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    String? nameError,
    String? productError,
    String? licenseKeyError,
    String? seatsError,
    String? maxActivationsError,
    String? activatedOnError,
    String? purchaseDateError,
    String? expiresAtError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _LicenseKeyFormState;

  const LicenseKeyFormState._();
}
