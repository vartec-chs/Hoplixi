import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_settings_state.freezed.dart';

/// Состояние настроек хранилища
@freezed
sealed class StoreSettingsState with _$StoreSettingsState {
  const factory StoreSettingsState({
    /// Текущее имя хранилища
    @Default('') String name,

    /// Текущее описание хранилища
    String? description,

    /// Новое имя (в процессе редактирования)
    @Default('') String newName,

    /// Новое описание (в процессе редактирования)
    String? newDescription,

    /// Ошибка валидации имени
    String? nameError,

    /// Текущий пароль (для смены)
    @Default('') String currentPassword,

    /// Новый пароль
    @Default('') String newPassword,

    /// Подтверждение нового пароля
    @Default('') String newPasswordConfirmation,

    /// Ошибка валидации текущего пароля
    String? currentPasswordError,

    /// Ошибка валидации нового пароля
    String? newPasswordError,

    /// Ошибка валидации подтверждения пароля
    String? newPasswordConfirmationError,

    /// Флаг смены пароля
    @Default(false) bool isChangingPassword,

    /// Флаг сохранения
    @Default(false) bool isSaving,

    /// Ошибка сохранения
    String? saveError,

    /// Успешное сообщение
    String? successMessage,
  }) = _StoreSettingsState;

  const StoreSettingsState._();

  /// Проверка возможности сохранения
  bool get canSave =>
      !isSaving &&
      newName.trim().isNotEmpty &&
      nameError == null &&
      (newName.trim() != name || newDescription != description);

  /// Проверка возможности смены пароля
  bool get canChangePassword =>
      !isChangingPassword &&
      currentPassword.isNotEmpty &&
      newPassword.isNotEmpty &&
      newPasswordConfirmation.isNotEmpty &&
      currentPasswordError == null &&
      newPasswordError == null &&
      newPasswordConfirmationError == null;
}
