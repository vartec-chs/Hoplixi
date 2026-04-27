import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/models/db_ciphers.dart';
import 'package:hoplixi/main_db/new/config/store_settings_keys.dart';
import 'package:hoplixi/main_db/new/providers/dao_providers.dart';
import 'package:hoplixi/main_db/new/providers/db_history_provider.dart';
import 'package:hoplixi/main_db/new/providers/main_store_manager_provider.dart';
import 'package:hoplixi/main_db/new/providers/service_providers.dart';
import 'package:hoplixi/main_db/new/services/db_key_derivation_service.dart';
import 'package:hoplixi/main_db/new/services/store_manifest_service/store_manifest_service.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hoplixi/features/password_manager/store_settings/models/store_settings_state.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

/// Провайдер для управления настройками хранилища
final storeSettingsProvider =
    NotifierProvider.autoDispose<StoreSettingsNotifier, StoreSettingsState>(
      StoreSettingsNotifier.new,
    );

/// Notifier для управления настройками хранилища
class StoreSettingsNotifier extends Notifier<StoreSettingsState> {
  static const String _logTag = 'StoreSettingsNotifier';

  @override
  StoreSettingsState build() {
    _loadCurrentSettings();
    return const StoreSettingsState();
  }

  /// Загрузить текущие настройки из базы
  Future<void> _loadCurrentSettings() async {
    try {
      String? currentDbCipher;
      String? currentDbCipherDescription;

      try {
        final manager = await ref.read(mainStoreManagerProvider.future);
        final db = manager.currentStore;
        if (db != null) {
          final pragmaRows = await db.customSelect('PRAGMA cipher;').get();
          if (pragmaRows.isNotEmpty) {
            final rawValue = pragmaRows.first.data.values.isNotEmpty
                ? pragmaRows.first.data.values.first
                : null;
            final cipherValue = rawValue
                ?.toString()
                .replaceAll('"', '')
                .trim()
                .toLowerCase();
            if (cipherValue!.isNotEmpty) {
              currentDbCipher = cipherValue;
              currentDbCipherDescription = dbCipherDescriptions[cipherValue];
            }
          }
        }
      } catch (e) {
        logWarning(
          'Failed to read current cipher via PRAGMA: $e',
          tag: _logTag,
        );
      }

      state = state.copyWith(
        currentDbCipher: currentDbCipher,
        currentDbCipherDescription: currentDbCipherDescription,
        isCipherLoading: false,
      );

      final daoResult = await ref.read(storeMetaDaoProvider.future);
      final meta = await daoResult.getStoreMeta();

      final settingsDao = await ref.read(storeSettingsDaoProvider.future);

      final historyLimitStr = await settingsDao.getSetting(
        StoreSettingsKeys.historyLimit,
      );
      final historyMaxAgeDaysStr = await settingsDao.getSetting(
        StoreSettingsKeys.historyMaxAgeDays,
      );
      final historyEnabledStr = await settingsDao.getSetting(
        StoreSettingsKeys.historyEnabled,
      );
      final incrementUsageOnCopyStr = await settingsDao.getSetting(
        StoreSettingsKeys.incrementUsageOnCopy,
      );
      final historyCleanupIntervalDaysStr = await settingsDao.getSetting(
        StoreSettingsKeys.historyCleanupIntervalDays,
      );

      final historyLimit = historyLimitStr != null
          ? int.tryParse(historyLimitStr) ?? 100
          : 100;
      final historyMaxAgeDays = historyMaxAgeDaysStr != null
          ? int.tryParse(historyMaxAgeDaysStr) ?? 30
          : 30;
      final historyEnabled = historyEnabledStr != null
          ? historyEnabledStr == 'true'
          : true;
      final incrementUsageOnCopy = incrementUsageOnCopyStr != null
          ? incrementUsageOnCopyStr == 'true'
          : true;
      final historyCleanupIntervalDays = historyCleanupIntervalDaysStr != null
          ? int.tryParse(historyCleanupIntervalDaysStr) ?? 7
          : 7;

      final pinnedRaw = await settingsDao.getSetting(
        StoreSettingsKeys.pinnedEntityTypes,
      );
      final pinnedIds = _parsePinnedEntityTypes(pinnedRaw);

      if (meta != null) {
        state = state.copyWith(
          name: meta.name,
          description: meta.description,
          newName: meta.name,
          newDescription: meta.description,
          historyLimit: historyLimit,
          historyMaxAgeDays: historyMaxAgeDays,
          historyEnabled: historyEnabled,
          incrementUsageOnCopy: incrementUsageOnCopy,
          historyCleanupIntervalDays: historyCleanupIntervalDays,
          newHistoryLimit: historyLimit,
          newHistoryMaxAgeDays: historyMaxAgeDays,
          newHistoryEnabled: historyEnabled,
          newIncrementUsageOnCopy: incrementUsageOnCopy,
          newHistoryCleanupIntervalDays: historyCleanupIntervalDays,
          pinnedEntityTypes: pinnedIds,
          newPinnedEntityTypes: pinnedIds,
        );
      }
    } catch (e, s) {
      logError(
        'Failed to load store settings: $e',
        stackTrace: s,
        tag: _logTag,
      );
      state = state.copyWith(
        saveError: 'Не удалось загрузить настройки хранилища',
        isCipherLoading: false,
      );
    }
  }

  /// Обновить имя
  void updateName(String name) {
    state = state.copyWith(
      newName: name,
      nameError: _validateName(name),
      saveError: null,
      successMessage: null,
    );
  }

  /// Обновить описание
  void updateDescription(String? description) {
    state = state.copyWith(
      newDescription: description,
      saveError: null,
      successMessage: null,
    );
  }

  /// Обновить лимит истории
  void updateHistoryLimit(int limit) {
    state = state.copyWith(
      newHistoryLimit: limit,
      saveError: null,
      successMessage: null,
    );
  }

  /// Обновить возраст истории
  void updateHistoryMaxAgeDays(int days) {
    state = state.copyWith(
      newHistoryMaxAgeDays: days,
      saveError: null,
      successMessage: null,
    );
  }

  /// Обновить состояние истории
  void updateHistoryEnabled(bool enabled) {
    state = state.copyWith(
      newHistoryEnabled: enabled,
      saveError: null,
      successMessage: null,
    );
  }

  /// Обновить настройку инкремента использования при копировании
  void updateIncrementUsageOnCopy(bool enabled) {
    state = state.copyWith(
      newIncrementUsageOnCopy: enabled,
      saveError: null,
      successMessage: null,
    );
  }

  /// Обновить интервал очистки истории
  void updateHistoryCleanupIntervalDays(int days) {
    state = state.copyWith(
      newHistoryCleanupIntervalDays: days,
      saveError: null,
      successMessage: null,
    );
  }

  /// Обновить закреплённые типы сущностей
  void updatePinnedEntityTypes(List<String> ids) {
    state = state.copyWith(
      newPinnedEntityTypes: ids,
      saveError: null,
      successMessage: null,
    );
  }

  /// Сохранить изменения
  AsyncResultDart<bool, String> save() async {
    if (!state.canSave) {
      return const Failure('Невозможно сохранить изменения');
    }

    state = state.copyWith(
      isSaving: true,
      saveError: null,
      successMessage: null,
    );

    try {
      final daoResult = await ref.read(storeMetaDaoProvider.future);
      var settingsChanged = false;

      // Обновляем имя если изменилось
      if (state.newName.trim() != state.name) {
        final nameUpdated = await daoResult.updateName(state.newName.trim());
        if (!nameUpdated) {
          state = state.copyWith(
            isSaving: false,
            saveError: 'Не удалось обновить имя хранилища',
          );
          return const Failure('Не удалось обновить имя хранилища');
        }
      }

      // Обновляем описание если изменилось
      if (state.newDescription != state.description) {
        final descUpdated = await daoResult.updateDescription(
          state.newDescription,
        );
        if (!descUpdated) {
          state = state.copyWith(
            isSaving: false,
            saveError: 'Не удалось обновить описание хранилища',
          );
          return const Failure('Не удалось обновить описание хранилища');
        }
      }

      final settingsDao = await ref.read(storeSettingsDaoProvider.future);
      bool shouldCleanupHistory = false;

      if (state.newHistoryLimit != state.historyLimit) {
        await settingsDao.setSetting(
          StoreSettingsKeys.historyLimit,
          state.newHistoryLimit.toString(),
        );
        settingsChanged = true;
        shouldCleanupHistory = true;
      }
      if (state.newHistoryMaxAgeDays != state.historyMaxAgeDays) {
        await settingsDao.setSetting(
          StoreSettingsKeys.historyMaxAgeDays,
          state.newHistoryMaxAgeDays.toString(),
        );
        settingsChanged = true;
        shouldCleanupHistory = true;
      }
      if (state.newHistoryEnabled != state.historyEnabled) {
        await settingsDao.setSetting(
          StoreSettingsKeys.historyEnabled,
          state.newHistoryEnabled.toString(),
        );
        settingsChanged = true;
        shouldCleanupHistory = true;
      }
      if (state.newIncrementUsageOnCopy != state.incrementUsageOnCopy) {
        await settingsDao.setSetting(
          StoreSettingsKeys.incrementUsageOnCopy,
          state.newIncrementUsageOnCopy.toString(),
        );
        settingsChanged = true;
      }
      if (state.newHistoryCleanupIntervalDays !=
          state.historyCleanupIntervalDays) {
        await settingsDao.setSetting(
          StoreSettingsKeys.historyCleanupIntervalDays,
          state.newHistoryCleanupIntervalDays.toString(),
        );
        settingsChanged = true;
      }

      if (!_listEquals(state.newPinnedEntityTypes, state.pinnedEntityTypes)) {
        await settingsDao.setSetting(
          StoreSettingsKeys.pinnedEntityTypes,
          jsonEncode(state.newPinnedEntityTypes),
        );
        settingsChanged = true;
        // Сбрасываем кэш провайдера закреплённых типов
        ref.invalidate(storeSettingsDaoProvider);
      }

      if (settingsChanged) {
        await daoResult.touchModifiedAt();
      }

      if (shouldCleanupHistory) {
        final cleanupService = await ref.read(
          storeCleanupServiceProvider.future,
        );
        await cleanupService.performFullCleanup(ignoreInterval: true);
      }

      // Обновляем состояние успешно
      state = state.copyWith(
        isSaving: false,
        name: state.newName.trim(),
        description: state.newDescription,
        historyLimit: state.newHistoryLimit,
        historyMaxAgeDays: state.newHistoryMaxAgeDays,
        historyEnabled: state.newHistoryEnabled,
        incrementUsageOnCopy: state.newIncrementUsageOnCopy,
        historyCleanupIntervalDays: state.newHistoryCleanupIntervalDays,
        pinnedEntityTypes: state.newPinnedEntityTypes,
        successMessage: 'Настройки успешно сохранены',
      );

      // Обновляем информацию в истории баз данных
      await _updateDatabaseHistory();

      logInfo('Store settings saved successfully', tag: _logTag);
      return const Success(true);
    } catch (e, s) {
      logError(
        'Failed to save store settings: $e',
        stackTrace: s,
        tag: _logTag,
      );
      state = state.copyWith(
        isSaving: false,
        saveError: 'Ошибка при сохранении: ${e.toString()}',
      );
      return Failure(e.toString());
    }
  }

  /// Сбросить форму к исходным значениям
  void reset() {
    state = state.copyWith(
      newName: state.name,
      newDescription: state.description,
      newHistoryLimit: state.historyLimit,
      newHistoryMaxAgeDays: state.historyMaxAgeDays,
      newHistoryEnabled: state.historyEnabled,
      newIncrementUsageOnCopy: state.incrementUsageOnCopy,
      newHistoryCleanupIntervalDays: state.historyCleanupIntervalDays,
      newPinnedEntityTypes: state.pinnedEntityTypes,
      nameError: null,
      saveError: null,
      successMessage: null,
    );
  }

  /// Парсинг JSON-списка закреплённых типов
  static List<String> _parsePinnedEntityTypes(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Очистить сообщения
  void clearMessages() {
    state = state.copyWith(saveError: null, successMessage: null);
  }

  /// Обновить новый пароль
  void updateNewPassword(String password) {
    state = state.copyWith(
      newPassword: password,
      newPasswordError: _validateNewPassword(password),
      newPasswordConfirmationError: _validatePasswordConfirmation(
        password,
        state.newPasswordConfirmation,
      ),
      saveError: null,
      successMessage: null,
    );
  }

  /// Обновить подтверждение нового пароля
  void updateNewPasswordConfirmation(String confirmation) {
    state = state.copyWith(
      newPasswordConfirmation: confirmation,
      newPasswordConfirmationError: _validatePasswordConfirmation(
        state.newPassword,
        confirmation,
      ),
      saveError: null,
      successMessage: null,
    );
  }

  /// Сменить пароль хранилища
  AsyncResultDart<bool, String> changePassword() async {
    if (!state.canChangePassword) {
      return const Failure('Заполните все поля для смены пароля');
    }

    state = state.copyWith(
      isChangingPassword: true,
      saveError: null,
      successMessage: null,
    );

    try {
      final daoResult = await ref.read(storeMetaDaoProvider.future);
      final dbState = await ref.read(mainStoreProvider.future);
      final currentPath = dbState.path;

      if (currentPath == null) {
        state = state.copyWith(
          isChangingPassword: false,
          saveError: 'Не удалось определить текущее хранилище',
        );
        return const Failure('Не удалось определить текущее хранилище');
      }

      final manifest = await StoreManifestService.readFrom(currentPath);
      final keyConfig = manifest?.keyConfig;
      if (keyConfig == null) {
        state = state.copyWith(
          isChangingPassword: false,
          saveError:
              'Не найден keyConfig в store_manifest.json. Смена пароля невозможна.',
        );
        return const Failure(
          'Не найден keyConfig в store_manifest.json. Смена пароля невозможна.',
        );
      }

      final keyService = DbKeyDerivationService(getIt<FlutterSecureStorage>());
      final newPragmaKey = await keyService.derivePragmaKey(
        state.newPassword,
        keyConfig.argon2Salt,
        useDeviceKey: keyConfig.useDeviceKey,
      );

      final result = await daoResult.changePassword(newPragmaKey);

      final resultException = result.exceptionOrNull();

      if (resultException != null) {
        throw Exception(resultException);
      }

      // Генерируем новую соль и вычисляем хеш пароля
      final newSalt = const Uuid().v4();
      final newPasswordHash = _hashPassword(state.newPassword, newSalt);

      await daoResult.updatePasswordHash(
        newPasswordHash: newPasswordHash,
        newSalt: newSalt,
      );

      // Обновляем пароль в истории, если он был сохранён
      await _updatePasswordInHistory(currentPath, state.newPassword);

      // Очищаем поля паролей
      state = state.copyWith(
        isChangingPassword: false,
        newPassword: '',
        newPasswordConfirmation: '',
        newPasswordError: null,
        newPasswordConfirmationError: null,
        successMessage: 'Пароль успешно изменен',
      );

      logInfo('Password changed successfully', tag: _logTag);
      return const Success(true);
    } catch (e, s) {
      logError('Failed to change password: $e', stackTrace: s, tag: _logTag);
      state = state.copyWith(
        isChangingPassword: false,
        saveError: 'Ошибка при смене пароля: ${e.toString()}',
      );
      return Failure(e.toString());
    }
  }

  /// Сбросить поля смены пароля
  void resetPasswordFields() {
    state = state.copyWith(
      newPassword: '',
      newPasswordConfirmation: '',
      newPasswordError: null,
      newPasswordConfirmationError: null,
    );
  }

  /// Обновить информацию о хранилище в истории баз данных
  Future<void> _updateDatabaseHistory() async {
    try {
      // Получаем текущее состояние базы данных
      final dbState = await ref.read(mainStoreProvider.future);
      final currentPath = dbState.path;

      if (currentPath == null) {
        logWarning(
          'Cannot update database history: current path is null',
          tag: _logTag,
        );
        return;
      }

      // Получаем сервис истории
      final historyService = await ref.read(dbHistoryProvider.future);

      // Получаем текущую запись из истории
      final existingEntry = await historyService.getByPath(currentPath);

      if (existingEntry == null) {
        logWarning(
          'Cannot update database history: entry not found for path $currentPath',
          tag: _logTag,
        );
        return;
      }

      // Обновляем запись с новыми данными
      final updatedEntry = existingEntry.copyWith(
        name: state.name,
        description: state.description,
      );

      await historyService.update(updatedEntry);

      logInfo(
        'Database history updated successfully for path: $currentPath',
        tag: _logTag,
      );
    } catch (e, s) {
      logError(
        'Failed to update database history: $e',
        stackTrace: s,
        tag: _logTag,
      );
      // Не прерываем операцию сохранения, если обновление истории не удалось
    }
  }

  /// Обновить пароль в истории баз данных (если он был сохранён)
  Future<void> _updatePasswordInHistory(
    String currentPath,
    String newPassword,
  ) async {
    try {
      final historyService = await ref.read(dbHistoryProvider.future);
      final existingEntry = await historyService.getByPath(currentPath);

      if (existingEntry == null) {
        logWarning(
          'Cannot update password in history: entry not found for path $currentPath',
          tag: _logTag,
        );
        return;
      }

      // Обновляем пароль только если пользователь сохранял его ранее
      if (existingEntry.savePassword) {
        await historyService.setSavedPasswordByPath(currentPath, newPassword);
        logInfo(
          'Password updated in database history for path: $currentPath',
          tag: _logTag,
        );
      } else {
        logInfo('Password not saved in history, skipping update', tag: _logTag);
      }
    } catch (e, s) {
      logError(
        'Failed to update password in database history: $e',
        stackTrace: s,
        tag: _logTag,
      );
      // Не прерываем операцию смены пароля, если обновление истории не удалось
    }
  }

  // Валидация

  String? _validateName(String name) {
    if (name.trim().isEmpty) {
      return 'Имя хранилища не может быть пустым';
    }
    if (name.trim().length < 3) {
      return 'Имя должно содержать минимум 3 символа';
    }
    if (name.trim().length > 50) {
      return 'Имя не может быть длиннее 50 символов';
    }
    // Проверка на недопустимые символы
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(name)) {
      return 'Имя содержит недопустимые символы';
    }
    return null;
  }

  String? _validateNewPassword(String password) {
    if (password.isEmpty) {
      return 'Введите новый пароль';
    }
    if (password.length < 4) {
      return 'Пароль должен содержать минимум 4 символа';
    }
    if (password.length > 128) {
      return 'Пароль слишком длинный (макс. 128 символов)';
    }
    return null;
  }

  String? _validatePasswordConfirmation(String password, String confirmation) {
    if (confirmation.isEmpty) {
      return 'Подтвердите новый пароль';
    }
    if (password != confirmation) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  /// Хешировать пароль с солью (аналогично MainStoreManager)
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha512.convert(bytes);
    return digest.toString();
  }
}
