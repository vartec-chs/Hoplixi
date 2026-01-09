import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_card_form_state.freezed.dart';

/// Состояние формы банковской карты
@freezed
sealed class BankCardFormState with _$BankCardFormState {
  const factory BankCardFormState({
    // Режим формы
    @Default(false) bool isEditMode,
    String? editingBankCardId,

    // Основные поля карты
    @Default('') String name,
    @Default('') String cardholderName,
    @Default('') String cardNumber,
    @Default('') String expiryMonth,
    @Default('') String expiryYear,
    @Default('') String cvv,

    // Дополнительные поля
    @Default('') String bankName,
    @Default('') String accountNumber,
    @Default('') String routingNumber,
    @Default('') String description,
    String? noteId,

    // Тип карты и сеть
    String? cardType,
    String? cardNetwork,

    // Связи
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,

    // Ошибки валидации
    String? nameError,
    String? cardholderNameError,
    String? cardNumberError,
    String? expiryMonthError,
    String? expiryYearError,
    String? cvvError,
    String? bankNameError,

    // Состояние загрузки
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,

    // Флаг успешного сохранения
    @Default(false) bool isSaved,

    // Фокус на CVV (для переворота карты)
    @Default(false) bool isCvvFocused,
  }) = _BankCardFormState;

  const BankCardFormState._();

  /// Проверка валидности формы
  bool get isValid {
    return nameError == null &&
        cardholderNameError == null &&
        cardNumberError == null &&
        expiryMonthError == null &&
        expiryYearError == null &&
        cvvError == null &&
        name.isNotEmpty &&
        cardholderName.isNotEmpty &&
        cardNumber.isNotEmpty &&
        expiryMonth.isNotEmpty &&
        expiryYear.isNotEmpty;
  }

  /// Есть ли хоть одна ошибка
  bool get hasErrors {
    return nameError != null ||
        cardholderNameError != null ||
        cardNumberError != null ||
        expiryMonthError != null ||
        expiryYearError != null ||
        cvvError != null ||
        bankNameError != null;
  }

  /// Форматированная дата истечения для CreditCardWidget
  String get formattedExpiryDate {
    if (expiryMonth.isEmpty || expiryYear.isEmpty) return '';
    final month = expiryMonth.padLeft(2, '0');
    final year = expiryYear.length >= 2
        ? expiryYear.substring(expiryYear.length - 2)
        : expiryYear;
    return '$month/$year';
  }
}
