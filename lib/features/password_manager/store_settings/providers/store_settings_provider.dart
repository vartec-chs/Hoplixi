import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/store_settings/models/store_settings_state.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/main_store/provider/db_history_provider.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:result_dart/result_dart.dart';

/// Провайдер для управления настройками хранилища
final storeSettingsProvider =
    NotifierProvider<StoreSettingsNotifier, StoreSettingsState>(
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
      final daoResult = await ref.read(storeMetaDaoProvider.future);
      final meta = await daoResult.getStoreMeta();

      if (meta != null) {
        state = state.copyWith(
          name: meta.name,
          description: meta.description,
          newName: meta.name,
          newDescription: meta.description,
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

      // Обновляем состояние успешно
      state = state.copyWith(
        isSaving: false,
        name: state.newName.trim(),
        description: state.newDescription,
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
      nameError: null,
      saveError: null,
      successMessage: null,
    );
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

      // База уже открыта с текущим паролем, поэтому проверка не требуется
      // Меняем пароль через SQLCipher PRAGMA rekey
      await daoResult.changePassword(state.newPassword);

      // Обновляем хеш и соль в мета-таблице
      // TODO: Здесь нужно вычислить новый хеш и соль
      // Пока используем простую заглушку
      final newPasswordHash = state.newPassword; // Заглушка
      final newSalt = 'new_salt'; // Заглушка

      await daoResult.updatePasswordHash(
        newPasswordHash: newPasswordHash,
        newSalt: newSalt,
      );

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
}
