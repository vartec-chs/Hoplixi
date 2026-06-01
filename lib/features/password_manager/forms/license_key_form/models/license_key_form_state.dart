import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';

part 'license_key_form_state.freezed.dart';

@freezed
sealed class LicenseKeyFormState with _$LicenseKeyFormState {
  const factory LicenseKeyFormState({
    @Default(false) bool isEditMode,
    String? editingLicenseKeyId,
    @Default('') String name,
    @Default('') String productName,
    @Default('') String vendor,
    @Default('') String licenseKey,
    String? licenseType,
    @Default('') String licenseTypeOther,
    @Default('') String accountEmail,
    @Default('') String accountUsername,
    @Default('') String purchaseEmail,
    @Default('') String orderNumber,
    @Default('') String purchaseDate,
    @Default('') String purchasePrice,
    @Default('') String currency,
    @Default('') String validFrom,
    @Default('') String validTo,
    @Default('') String renewalDate,
    @Default('') String seats,
    @Default('') String activationLimit,
    @Default('') String activationsUsed,
    @Default('') String description,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    @Default([]) List<CustomFieldEntry> customFields,
    String? nameError,
    String? productNameError,
    String? licenseKeyError,
    String? seatsError,
    String? activationLimitError,
    String? activationsUsedError,
    String? purchaseDateError,
    String? validFromError,
    String? validToError,
    String? renewalDateError,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _LicenseKeyFormState;

  const LicenseKeyFormState._();
}
