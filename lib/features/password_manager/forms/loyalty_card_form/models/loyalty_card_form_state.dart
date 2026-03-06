import 'package:freezed_annotation/freezed_annotation.dart';

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
    String? nameError,
    String? programNameError,
    String? cardNumberError,
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
        cardNumberError != null ||
        expiryDateError != null ||
        websiteError != null;
  }
}
