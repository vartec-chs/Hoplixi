import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/store_settings/models/store_settings_state.dart';
import 'package:hoplixi/main_db/config/store_settings_keys.dart';
import 'package:hoplixi/main_db/core/old/models/db_ciphers.dart';
import 'package:hoplixi/main_db/providers/db_history_provider.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/main_db/providers/other/service_providers.dart';
import 'package:hoplixi/main_db/services/db_key_derivation_service.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/model/store_manifest.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/store_manifest_service.dart';
import 'package:hoplixi/main_db/services/vault_key_file_service.dart';
import 'package:hoplixi/setup/di_init.dart';
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
      final dbState = await ref.read(mainStoreProvider.future);
      final manifest = dbState.path == null
          ? null
          : await StoreManifestService.readFrom(dbState.path!);

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
          useKeyFile: manifest?.useKeyFile ?? false,
          keyFileId: manifest?.keyFileId,
          keyFileHint: manifest?.keyFileHint,
          useDeviceKey: manifest?.keyConfig?.useDeviceKey ?? false,
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
        final cleanup = await ref.read(performStoreCleanupProvider.future);
        await cleanup(ignoreInterval: true);
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
    state = state.copyWith(
      saveError: null,
      keyFileSettingsError: null,
      deviceKeySettingsError: null,
      successMessage: null,
    );
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

      if (manifest!.useKeyFile) {
        if (state.selectedKeyFileId == null ||
            state.selectedKeyFileSecret == null) {
          state = state.copyWith(
            isChangingPassword: false,
            saveError: 'Выберите JSON key file для смены пароля.',
          );
          return const Failure('Выберите JSON key file для смены пароля.');
        }
        if (state.selectedKeyFileId != manifest.keyFileId) {
          state = state.copyWith(
            isChangingPassword: false,
            saveError:
                'Выбранный JSON key file не подходит для этого хранилища.',
          );
          return const Failure(
            'Выбранный JSON key file не подходит для этого хранилища.',
          );
        }
      }

      final keyService = DbKeyDerivationService(getIt<FlutterSecureStorage>());
      final newPragmaKey = await keyService.derivePragmaKey(
        state.newPassword,
        keyConfig.argon2Salt,
        useDeviceKey: keyConfig.useDeviceKey,
        keyFileSecret: manifest.useKeyFile ? state.selectedKeyFileSecret : null,
        kdfVersion: keyConfig.kdfVersion,
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
        selectedKeyFileId: null,
        selectedKeyFileHint: null,
        selectedKeyFileSecret: null,
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

  void updateKeyFilePassword(String password) {
    state = state.copyWith(
      keyFilePassword: password,
      keyFileSettingsError: null,
      successMessage: null,
    );
  }

  void updateDeviceKeyPassword(String password) {
    state = state.copyWith(
      deviceKeyPassword: password,
      deviceKeySettingsError: null,
      successMessage: null,
    );
  }

  Future<void> selectKeyFileForSettings() async {
    final result = await const VaultKeyFileService().pickAndRead();
    result.fold(
      (keyFile) => state = state.copyWith(
        selectedKeyFileId: keyFile.id,
        selectedKeyFileHint: keyFile.hint,
        selectedKeyFileSecret: keyFile.secret,
        keyFileSettingsError: null,
      ),
      (error) => state = state.copyWith(keyFileSettingsError: error.message),
    );
  }

  Future<void> generateKeyFileForSettings() async {
    final fileName = '${state.name.trim().replaceAll(' ', '_')}_key_file';
    final result = await const VaultKeyFileService().createAndSave(
      suggestedFileName: fileName,
      hint: state.selectedKeyFileHint ?? state.keyFileHint,
    );
    result.fold(
      (keyFile) => state = state.copyWith(
        selectedKeyFileId: keyFile.id,
        selectedKeyFileHint: keyFile.hint,
        selectedKeyFileSecret: keyFile.secret,
        keyFileSettingsError: null,
      ),
      (error) => state = state.copyWith(keyFileSettingsError: error.message),
    );
  }

  AsyncResultDart<bool, String> enableKeyFile(String masterPassword) async {
    if (masterPassword.isEmpty) {
      state = state.copyWith(
        keyFileSettingsError: 'Введите текущий мастер пароль',
      );
      return const Failure('Введите текущий мастер пароль');
    }
    if (state.selectedKeyFileId == null ||
        state.selectedKeyFileSecret == null) {
      state = state.copyWith(
        keyFileSettingsError: 'Выберите или сгенерируйте JSON key file',
      );
      return const Failure('Выберите или сгенерируйте JSON key file');
    }
    return _rekeyKeyFileSettings(enable: true, masterPassword: masterPassword);
  }

  AsyncResultDart<bool, String> disableKeyFile(String masterPassword) async {
    if (masterPassword.isEmpty) {
      state = state.copyWith(
        keyFileSettingsError: 'Введите текущий мастер пароль',
      );
      return const Failure('Введите текущий мастер пароль');
    }
    if (state.useKeyFile &&
        (state.selectedKeyFileId == null ||
            state.selectedKeyFileSecret == null)) {
      state = state.copyWith(
        keyFileSettingsError: 'Выберите текущий JSON key file',
      );
      return const Failure('Выберите текущий JSON key file');
    }
    if (state.useKeyFile && state.selectedKeyFileId != state.keyFileId) {
      state = state.copyWith(
        keyFileSettingsError:
            'Выбранный JSON key file не подходит для этого хранилища',
      );
      return const Failure(
        'Выбранный JSON key file не подходит для этого хранилища',
      );
    }
    return _rekeyKeyFileSettings(enable: false, masterPassword: masterPassword);
  }

  AsyncResultDart<bool, String> enableDeviceKey(String masterPassword) async {
    if (masterPassword.isEmpty) {
      state = state.copyWith(
        deviceKeySettingsError: 'Введите текущий мастер пароль',
      );
      return const Failure('Введите текущий мастер пароль');
    }
    if (state.useKeyFile &&
        (state.selectedKeyFileId == null ||
            state.selectedKeyFileSecret == null)) {
      state = state.copyWith(
        deviceKeySettingsError:
            'Выберите текущий JSON key file для переключения ключа устройства',
      );
      return const Failure(
        'Выберите текущий JSON key file для переключения ключа устройства',
      );
    }
    if (state.useKeyFile && state.selectedKeyFileId != state.keyFileId) {
      state = state.copyWith(
        deviceKeySettingsError:
            'Выбранный JSON key file не подходит для этого хранилища',
      );
      return const Failure(
        'Выбранный JSON key file не подходит для этого хранилища',
      );
    }
    return _rekeyDeviceKeySettings(enable: true, masterPassword: masterPassword);
  }

  AsyncResultDart<bool, String> disableDeviceKey(String masterPassword) async {
    if (masterPassword.isEmpty) {
      state = state.copyWith(
        deviceKeySettingsError: 'Введите текущий мастер пароль',
      );
      return const Failure('Введите текущий мастер пароль');
    }
    if (state.useKeyFile &&
        (state.selectedKeyFileId == null ||
            state.selectedKeyFileSecret == null)) {
      state = state.copyWith(
        deviceKeySettingsError:
            'Выберите текущий JSON key file для переключения ключа устройства',
      );
      return const Failure(
        'Выберите текущий JSON key file для переключения ключа устройства',
      );
    }
    if (state.useKeyFile && state.selectedKeyFileId != state.keyFileId) {
      state = state.copyWith(
        deviceKeySettingsError:
            'Выбранный JSON key file не подходит для этого хранилища',
      );
      return const Failure(
        'Выбранный JSON key file не подходит для этого хранилища',
      );
    }
    return _rekeyDeviceKeySettings(
      enable: false,
      masterPassword: masterPassword,
    );
  }

  AsyncResultDart<bool, String> _rekeyDeviceKeySettings({
    required bool enable,
    required String masterPassword,
  }) async {
    state = state.copyWith(
      isUpdatingDeviceKey: true,
      deviceKeySettingsError: null,
      saveError: null,
      successMessage: null,
    );

    try {
      final dao = await ref.read(storeMetaDaoProvider.future);
      final meta = await dao.getStoreMeta();
      if (meta == null) {
        throw StateError('Метаданные хранилища не найдены');
      }
      if (_hashPassword(masterPassword, meta.salt) != meta.passwordHash) {
        throw StateError('Текущий мастер пароль неверен');
      }

      final dbState = await ref.read(mainStoreProvider.future);
      final currentPath = dbState.path;
      if (currentPath == null) {
        throw StateError('Не удалось определить текущее хранилище');
      }

      final manifest = await StoreManifestService.readFrom(currentPath);
      final keyConfig = manifest?.keyConfig;
      if (manifest == null || keyConfig == null) {
        throw StateError('Не найден keyConfig в store_manifest.json');
      }

      final keyService = DbKeyDerivationService(getIt<FlutterSecureStorage>());
      final newPragmaKey = await keyService.derivePragmaKey(
        masterPassword,
        keyConfig.argon2Salt,
        useDeviceKey: enable,
        keyFileSecret: manifest.useKeyFile ? state.selectedKeyFileSecret : null,
        kdfVersion: keyConfig.kdfVersion,
      );

      final result = await dao.changePassword(newPragmaKey);
      final resultException = result.exceptionOrNull();
      if (resultException != null) {
        throw Exception(resultException);
      }

      final updatedManifest = manifest.copyWith(
        keyConfig: keyConfig.copyWith(useDeviceKey: enable),
        updatedAt: DateTime.now().toUtc(),
      );
      await StoreManifestService.writeTo(currentPath, updatedManifest);

      state = state.copyWith(
        isUpdatingDeviceKey: false,
        useDeviceKey: updatedManifest.keyConfig?.useDeviceKey ?? enable,
        deviceKeyPassword: '',
        selectedKeyFileId: null,
        selectedKeyFileHint: null,
        selectedKeyFileSecret: null,
        successMessage: enable
            ? 'Ключ устройства включён'
            : 'Ключ устройства отключён',
      );
      return const Success(true);
    } catch (e, s) {
      logError(
        'Failed to update device key settings: $e',
        stackTrace: s,
        tag: _logTag,
      );
      state = state.copyWith(
        isUpdatingDeviceKey: false,
        deviceKeySettingsError: e.toString(),
      );
      return Failure(e.toString());
    }
  }

  AsyncResultDart<bool, String> _rekeyKeyFileSettings({
    required bool enable,
    required String masterPassword,
  }) async {
    state = state.copyWith(
      isUpdatingKeyFile: true,
      keyFileSettingsError: null,
      saveError: null,
      successMessage: null,
    );

    try {
      final dao = await ref.read(storeMetaDaoProvider.future);
      final meta = await dao.getStoreMeta();
      if (meta == null) {
        throw StateError('Метаданные хранилища не найдены');
      }
      if (_hashPassword(masterPassword, meta.salt) != meta.passwordHash) {
        throw StateError('Текущий мастер пароль неверен');
      }

      final dbState = await ref.read(mainStoreProvider.future);
      final currentPath = dbState.path;
      if (currentPath == null) {
        throw StateError('Не удалось определить текущее хранилище');
      }

      final manifest = await StoreManifestService.readFrom(currentPath);
      final keyConfig = manifest?.keyConfig;
      if (manifest == null || keyConfig == null) {
        throw StateError('Не найден keyConfig в store_manifest.json');
      }

      final keyService = DbKeyDerivationService(getIt<FlutterSecureStorage>());
      final newPragmaKey = await keyService.derivePragmaKey(
        masterPassword,
        keyConfig.argon2Salt,
        useDeviceKey: keyConfig.useDeviceKey,
        keyFileSecret: enable ? state.selectedKeyFileSecret : null,
        kdfVersion: keyConfig.kdfVersion,
      );

      final result = await dao.changePassword(newPragmaKey);
      final resultException = result.exceptionOrNull();
      if (resultException != null) {
        throw Exception(resultException);
      }

      final updatedManifest = enable
          ? manifest.withKeyFile(
              keyFileId: state.selectedKeyFileId!,
              keyFileHint: state.selectedKeyFileHint,
            )
          : manifest.withoutKeyFile();
      await StoreManifestService.writeTo(currentPath, updatedManifest);

      state = state.copyWith(
        isUpdatingKeyFile: false,
        useKeyFile: updatedManifest.useKeyFile,
        keyFileId: updatedManifest.keyFileId,
        keyFileHint: updatedManifest.keyFileHint,
        selectedKeyFileId: null,
        selectedKeyFileHint: null,
        selectedKeyFileSecret: null,
        successMessage: enable
            ? 'JSON key file включён'
            : 'JSON key file отключён',
      );
      return const Success(true);
    } catch (e, s) {
      logError(
        'Failed to update key file settings: $e',
        stackTrace: s,
        tag: _logTag,
      );
      state = state.copyWith(
        isUpdatingKeyFile: false,
        keyFileSettingsError: e.toString(),
      );
      return Failure(e.toString());
    }
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
