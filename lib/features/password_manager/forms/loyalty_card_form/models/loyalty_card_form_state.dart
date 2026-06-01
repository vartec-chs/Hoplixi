import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';

part 'loyalty_card_form_state.freezed.dart';

@freezed
sealed class LoyaltyCardFormState with _$LoyaltyCardFormState {
  const factory LoyaltyCardFormState({
    @Default(false) bool isEditMode,
    String? editingLoyaltyCardId,
    @Default('') String name,
    @Default('') String programName,
    @Default('') String cardNumber,
    @Default('') String barcodeValue,
    @Default('') String password,
    String? barcodeType,
    @Default('') String barcodeTypeOther,
    @Default('') String issuer,
    @Default('') String website,
    @Default('') String phone,
    @Default('') String email,
    @Default('') String validFrom,
    @Default('') String validTo,
    @Default('') String description,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    @Default([]) List<CustomFieldEntry> customFields,
    String? nameError,
    String? programNameError,
    String? cardOrBarcodeError,
    String? validFromError,
    String? validToError,
    String? websiteError,
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
  }) = _LoyaltyCardFormState;

  const LoyaltyCardFormState._();

  bool get hasErrors {
    return nameError != null ||
        programNameError != null ||
        cardOrBarcodeError != null ||
        validFromError != null ||
        validToError != null ||
        websiteError != null;
  }
}
