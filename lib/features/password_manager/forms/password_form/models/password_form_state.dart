import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_form_state.freezed.dart';

/// Состояние формы пароля
@freezed
sealed class PasswordFormState with _$PasswordFormState {
  const factory PasswordFormState({
    // Режим формы
    @Default(false) bool isEditMode,
    String? editingPasswordId,

    // Поля формы
    @Default('') String name,
    @Default('') String password,
    @Default('') String login,
    @Default('') String email,
    @Default('') String url,
    @Default('') String description,
    String? noteId,
    String? otpId,
    String? otpName,

    // Связи
    String? categoryId,
    String? categoryName,
    @Default([]) List<String> tagIds,
    @Default([]) List<String> tagNames,

    // Ошибки валидации
    String? nameError,
    String? passwordError,
    String? loginError,
    String? emailError,
    String? urlError,

    // Состояние загрузки
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,

    // Флаг успешного сохранения
    @Default(false) bool isSaved,
  }) = _PasswordFormState;

  const PasswordFormState._();

  /// Проверка валидности формы
  bool get isValid {
    return nameError == null &&
        passwordError == null &&
        loginError == null &&
        emailError == null &&
        urlError == null &&
        name.isNotEmpty &&
        password.isNotEmpty &&
        (login.isNotEmpty || email.isNotEmpty);
  }

  /// Есть ли хоть одна ошибка
  bool get hasErrors {
    return nameError != null ||
        passwordError != null ||
        loginError != null ||
        emailError != null ||
        urlError != null;
  }
}
