import 'dart:typed_data';

import 'package:flutter/foundation.dart';
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

    /// Инкрементировать ли использование при копировании
    @Default(true) bool incrementUsageOnCopy,

    /// Новый лимит истории (в процессе редактирования)
    @Default(100) int newHistoryLimit,

    /// Новый максимальный возраст истории в днях (в процессе редактирования)
    @Default(30) int newHistoryMaxAgeDays,

    /// Новое состояние включения истории (в процессе редактирования)
    @Default(true) bool newHistoryEnabled,

    /// Новое состояние инкремента использования при копировании
    @Default(true) bool newIncrementUsageOnCopy,

    /// Интервал очистки истории в днях
    @Default(7) int historyCleanupIntervalDays,

    /// Новый интервал очистки истории в днях (в процессе редактирования)
    @Default(7) int newHistoryCleanupIntervalDays,

    /// Закреплённые типы сущностей (хранятся как список идентификаторов)
    @Default([]) List<String> pinnedEntityTypes,

    /// Новые закреплённые типы (в процессе редактирования)
    @Default([]) List<String> newPinnedEntityTypes,

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

    /// Текущий алгоритм шифрования БД из PRAGMA cipher
    String? currentDbCipher,

    /// Техническое описание текущего алгоритма
    String? currentDbCipherDescription,

    /// Идет ли загрузка информации о cipher
    @Default(true) bool isCipherLoading,

    /// Key file настройки из store_manifest.json.
    @Default(false) bool useKeyFile,
    String? keyFileId,
    String? keyFileHint,
    @Default('') String keyFilePassword,
    String? selectedKeyFileId,
    String? selectedKeyFileHint,
    @JsonKey(includeFromJson: false, includeToJson: false)
    Uint8List? selectedKeyFileSecret,
    @Default(false) bool isUpdatingKeyFile,
    String? keyFileSettingsError,
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
          newIncrementUsageOnCopy != incrementUsageOnCopy ||
          newHistoryCleanupIntervalDays != historyCleanupIntervalDays ||
          !listEquals(newPinnedEntityTypes, pinnedEntityTypes));

  /// Проверка возможности смены пароля
  bool get canChangePassword =>
      !isChangingPassword &&
      newPassword.isNotEmpty &&
      newPasswordConfirmation.isNotEmpty &&
      newPasswordError == null &&
      newPasswordConfirmationError == null;
}
