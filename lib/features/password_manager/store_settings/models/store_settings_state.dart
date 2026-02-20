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

    /// Лимит истории
    @Default(100) int historyLimit,

    /// Максимальный возраст истории в днях
    @Default(30) int historyMaxAgeDays,

    /// Включена ли история
    @Default(true) bool historyEnabled,

    /// Новый лимит истории (в процессе редактирования)
    @Default(100) int newHistoryLimit,

    /// Новый максимальный возраст истории в днях (в процессе редактирования)
    @Default(30) int newHistoryMaxAgeDays,

    /// Новое состояние включения истории (в процессе редактирования)
    @Default(true) bool newHistoryEnabled,

    /// Интервал очистки истории в днях
    @Default(7) int historyCleanupIntervalDays,

    /// Новый интервал очистки истории в днях (в процессе редактирования)
    @Default(7) int newHistoryCleanupIntervalDays,

    /// Ошибка валидации нового пароля
    @Default('') String newPassword,

    /// Подтверждение нового пароля
    @Default('') String newPasswordConfirmation,

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
      (newName.trim() != name ||
          newDescription != description ||
          newHistoryLimit != historyLimit ||
          newHistoryMaxAgeDays != historyMaxAgeDays ||
          newHistoryEnabled != historyEnabled ||
          newHistoryCleanupIntervalDays != historyCleanupIntervalDays);

  /// Проверка возможности смены пароля
  bool get canChangePassword =>
      !isChangingPassword &&
      newPassword.isNotEmpty &&
      newPasswordConfirmation.isNotEmpty &&
      newPasswordError == null &&
      newPasswordConfirmationError == null;
}
