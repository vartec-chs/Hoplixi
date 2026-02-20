import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/dto/password_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../models/password_form_state.dart';

const _logTag = 'PasswordFormProvider';

/// Провайдер состояния формы пароля
final passwordFormProvider =
    NotifierProvider.autoDispose<PasswordFormNotifier, PasswordFormState>(
      PasswordFormNotifier.new,
    );

/// Notifier для управления формой пароля
class PasswordFormNotifier extends Notifier<PasswordFormState> {
  @override
  PasswordFormState build() {
    return const PasswordFormState(isEditMode: false);
  }

  /// Инициализировать форму для создания нового пароля
  void initForCreate() {
    state = const PasswordFormState(isEditMode: false);
  }

  /// Инициализировать форму для редактирования пароля
  Future<void> initForEdit(String passwordId) async {
    state = state.copyWith(isLoading: true);

    try {
      final dao = await ref.read(passwordDaoProvider.future);
      final record = await dao.getById(passwordId);

      if (record == null) {
        logWarning('Password not found: $passwordId', tag: _logTag);
        state = state.copyWith(isLoading: false);
        return;
      }

      final (vault, pwItem) = record;
      final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
      final tagIds = await vaultItemDao.getTagIds(passwordId);
      final tagDao = await ref.read(tagDaoProvider.future);
      final tagRecords = await tagDao.getTagsByIds(tagIds);

      final otpDao = await ref.read(otpDaoProvider.future);
      final linkedOtp = await otpDao.getByPasswordItemId(passwordId);

      state = PasswordFormState(
        isEditMode: true,
        editingPasswordId: passwordId,
        name: vault.name,
        password: pwItem.password,
        login: pwItem.login ?? '',
        email: pwItem.email ?? '',
        url: pwItem.url ?? '',
        description: vault.description ?? '',
        noteId: vault.noteId,
        categoryId: vault.categoryId,
        tagIds: tagIds,
        tagNames: tagRecords.map((tag) => tag.name).toList(),
        otpId: linkedOtp?.$1.id,
        otpName: linkedOtp?.$1.name ?? linkedOtp?.$2.accountName,
        isLoading: false,
      );
    } catch (e, stack) {
      logError(
        'Failed to load password for editing',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// Обновить поле name
  void setName(String value) {
    state = state.copyWith(name: value, nameError: _validateName(value));
  }

  /// Обновить поле password
  void setPassword(String value) {
    state = state.copyWith(
      password: value,
      passwordError: _validatePassword(value),
    );
  }

  /// Обновить поле login
  void setLogin(String value) {
    state = state.copyWith(
      login: value,
      loginError: _validateLogin(value, state.email),
    );
  }

  /// Обновить поле email
  void setEmail(String value) {
    state = state.copyWith(
      email: value,
      emailError: _validateEmail(value, state.login),
    );
  }

  /// Обновить поле url
  void setUrl(String value) {
    state = state.copyWith(url: value, urlError: _validateUrl(value));
  }

  /// Обновить поле description
  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  /// Обновить поле noteId
  void setNoteId(String? value) {
    state = state.copyWith(noteId: value);
  }

  /// Обновить поле otpId
  void setOtp(String? otpId, String? otpName) {
    state = state.copyWith(otpId: otpId, otpName: otpName);
  }

  /// Обновить категорию
  void setCategory(String? categoryId, String? categoryName) {
    state = state.copyWith(categoryId: categoryId, categoryName: categoryName);
  }

  /// Обновить теги
  void setTags(List<String> tagIds, List<String> tagNames) {
    state = state.copyWith(tagIds: tagIds, tagNames: tagNames);
  }

  /// Валидация имени
  String? _validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Название обязательно';
    }
    if (value.trim().length > 255) {
      return 'Название не должно превышать 255 символов';
    }
    return null;
  }

  /// Валидация пароля
  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Пароль обязателен';
    }
    if (value.isEmpty) {
      return 'Пароль не может быть пустым';
    }
    return null;
  }

  /// Валидация логина (должен быть заполнен логин или email)
  String? _validateLogin(String login, String email) {
    if (login.trim().isEmpty && email.trim().isEmpty) {
      return 'Заполните логин или email';
    }
    return null;
  }

  /// Валидация email (должен быть заполнен логин или email)
  String? _validateEmail(String email, String login) {
    if (email.trim().isEmpty && login.trim().isEmpty) {
      return 'Заполните email или логин';
    }

    if (email.trim().isNotEmpty && !_isValidEmail(email)) {
      return 'Неверный формат email';
    }

    return null;
  }

  /// Валидация URL
  String? _validateUrl(String value) {
    if (value.trim().isEmpty) {
      return null; // URL опционален
    }

    if (!_isValidUrl(value)) {
      return 'Неверный формат URL';
    }

    return null;
  }

  /// Проверка формата email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Проверка формата URL
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url.trim());
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Валидировать все поля формы
  bool validateAll() {
    final nameError = _validateName(state.name);
    final passwordError = _validatePassword(state.password);
    final loginError = _validateLogin(state.login, state.email);
    final emailError = _validateEmail(state.email, state.login);
    final urlError = _validateUrl(state.url);

    state = state.copyWith(
      nameError: nameError,
      passwordError: passwordError,
      loginError: loginError,
      emailError: emailError,
      urlError: urlError,
    );

    return !state.hasErrors;
  }

  /// Сохранить форму
  Future<bool> save() async {
    // Валидация
    if (!validateAll()) {
      logWarning('Form validation failed', tag: _logTag);
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      final dao = await ref.read(passwordDaoProvider.future);

      if (state.isEditMode && state.editingPasswordId != null) {
        // Режим редактирования
        final dto = UpdatePasswordDto(
          name: state.name.trim(),
          password: state.password,
          login: state.login.trim().isEmpty ? null : state.login.trim(),
          email: state.email.trim().isEmpty ? null : state.email.trim(),
          url: state.url.trim().isEmpty ? null : state.url.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          noteId: state.noteId,
          categoryId: state.categoryId,
        );

        final success = await dao.updatePassword(state.editingPasswordId!, dto);

        if (success) {
          final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
          await vaultItemDao.syncTags(state.editingPasswordId!, state.tagIds);
          await _updateOtpLink(state.editingPasswordId!);

          logInfo('Password updated: ${state.editingPasswordId}', tag: _logTag);
          state = state.copyWith(isSaving: false, isSaved: true);

          // Триггерим обновление списка паролей
          ref
              .read(dataRefreshTriggerProvider.notifier)
              .triggerEntityUpdate(
                EntityType.password,
                entityId: state.editingPasswordId,
              );

          return true;
        } else {
          logWarning(
            'Failed to update password: ${state.editingPasswordId}',
            tag: _logTag,
          );
          state = state.copyWith(isSaving: false);
          return false;
        }
      } else {
        // Режим создания
        final dto = CreatePasswordDto(
          name: state.name.trim(),
          password: state.password,
          login: state.login.trim().isEmpty ? null : state.login.trim(),
          email: state.email.trim().isEmpty ? null : state.email.trim(),
          url: state.url.trim().isEmpty ? null : state.url.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          noteId: state.noteId,
          categoryId: state.categoryId,
          tagsIds: state.tagIds.isEmpty ? null : state.tagIds,
        );

        final passwordId = await dao.createPassword(dto);
        await _updateOtpLink(passwordId);

        logInfo('Password created: $passwordId', tag: _logTag);
        state = state.copyWith(isSaving: false, isSaved: true);

        // Триггерим обновление списка паролей
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.password, entityId: passwordId);

        return true;
      }
    } catch (e, stack) {
      logError(
        'Failed to save password',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  /// Сбросить флаг сохранения
  void resetSaved() {
    state = state.copyWith(isSaved: false);
  }

  /// Обновить привязку OTP
  Future<void> _updateOtpLink(String passwordId) async {
    try {
      final otpDao = await ref.read(otpDaoProvider.future);
      // 1. Найти текущие привязки
      final currentLinkedOtp = await otpDao.getByPasswordItemId(passwordId);

      // 2. Отвязать лишние
      if (currentLinkedOtp != null) {
        if (currentLinkedOtp.$1.id != state.otpId) {
          await otpDao.updateOtpLink(currentLinkedOtp.$1.id, null);
        }
      }

      // 3. Привязать новый
      if (state.otpId != null) {
        await otpDao.updateOtpLink(state.otpId!, passwordId);
      }
    } catch (e) {
      logError('Failed to update OTP link', error: e, tag: _logTag);
    }
  }
}
