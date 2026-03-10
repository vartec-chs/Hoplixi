import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/shared/custom_fields/models/custom_field_entry.dart';

part 'loyalty_card_form_state.freezed.dart';

@freezed
sealed class LoyaltyCardFormState with _$LoyaltyCardFormState {
  const factory LoyaltyCardFormState({
    @Default(false) bool isEditMode,
    String? editingLoyaltyCardId,
    @Default('') String name,
    @Default('') String programName,
    @Default('') String cardNumber,
    @Default('') String holderName,
    @Default('') String password,
    @Default('') String barcodeValue,
    @Default('') String barcodeType,
    @Default('') String pointsBalance,
    @Default('') String tier,
    @Default('') String expiryDate,
    @Default('') String website,
    @Default('') String phoneNumber,
    @Default('') String description,
    String? noteId,
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    @Default([]) List<CustomFieldEntry> customFields,
    String? nameError,
    String? programNameError,
    String? cardOrBarcodeError,
    String? expiryDateError,
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
        expiryDateError != null ||
        websiteError != null;
  }
}
