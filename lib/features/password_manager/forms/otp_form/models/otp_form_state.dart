import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';

part 'otp_form_state.freezed.dart';

/// Состояние формы OTP
@freezed
sealed class OtpFormState with _$OtpFormState {
  const factory OtpFormState({
    // Режим формы
    @Default(false) bool isEditMode,
    String? editingOtpId,

    // Тип OTP (TOTP или HOTP)
    @Default(OtpType.totp) OtpType otpType,

    // Основные поля формы
    @Default('') String issuer,
    @Default('') String accountName,
    @Default('') String secret,
    String? noteId,

    // Настройки OTP
    @Default(AlgorithmOtp.SHA1) AlgorithmOtp algorithm,
    @Default(6) int digits,
    @Default(30) int period,
    int? counter,

    // Связи
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,
    String? passwordId,

    // Ошибки валидации
    String? issuerError,
    String? accountNameError,
    String? secretError,
    String? digitsError,
    String? periodError,
    String? counterError,

    // Состояние загрузки
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,

    // Флаг успешного сохранения
    @Default(false) bool isSaved,

    // Флаг: данные загружены из QR-кода
    @Default(false) bool isFromQrCode,
  }) = _OtpFormState;

  const OtpFormState._();

  /// Проверка валидности формы
  bool get isValid {
    return secretError == null &&
        digitsError == null &&
        periodError == null &&
        secret.isNotEmpty;
  }

  /// Есть ли хоть одна ошибка
  bool get hasErrors {
    return secretError != null ||
        digitsError != null ||
        periodError != null ||
        counterError != null;
  }

  /// Отображаемое название (issuer или accountName)
  String get displayName {
    if (issuer.isNotEmpty) return issuer;
    if (accountName.isNotEmpty) return accountName;
    return 'Без названия';
  }
}
