import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/providers/repository_providers.dart';

import '../models/password_form_state.dart';

const _logTag = 'PasswordFormProvider';

final passwordFormProvider =
    NotifierProvider.autoDispose<PasswordFormNotifier, PasswordFormState>(
      PasswordFormNotifier.new,
    );

class PasswordFormNotifier extends Notifier<PasswordFormState> {
  @override
  PasswordFormState build() {
    return const PasswordFormState(isEditMode: false);
  }

  void initForCreate() {
    state = const PasswordFormState(isEditMode: false);
  }

  Future<void> initForEdit(String passwordId) async {
    state = state.copyWith(isLoading: true);

    try {
      final repository = await ref.read(passwordRepositoryProvider.future);
      final view = await repository.getViewById(passwordId);

      if (view == null) {
        logWarning('Password not found: $passwordId', tag: _logTag);
        state = state.copyWith(isLoading: false);
        return;
      }

      final item = view.item;
      final details = view.password;
      
      // TODO: handle tags properly
      final tagIds = <String>[];
      final tagNames = <String>[];

      // TODO: handle OTP link properly via ItemLinkRepository or RelationsService
      String? otpId;
      String? otpName;

      final customFields = await loadCustomFields(ref, passwordId);

      state = PasswordFormState(
        isEditMode: true,
        editingPasswordId: passwordId,
        name: item.name,
        password: details.password,
        login: details.login ?? '',
        email: details.email ?? '',
        url: details.url ?? '',
        description: item.description ?? '',
        categoryId: item.categoryId,
        expireAt: details.expiresAt,
        tagIds: tagIds,
        tagNames: tagNames,
        otpId: otpId,
        otpName: otpName,
        customFields: customFields,
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

  void setName(String value) {
    state = state.copyWith(name: value, nameError: _validateName(value));
  }

  void setPassword(String value) {
    state = state.copyWith(
      password: value,
      passwordError: _validatePassword(value),
    );
  }

  void setLogin(String value) {
    state = state.copyWith(
      login: value,
      loginError: _validateLogin(value, state.email),
    );
  }

  void setEmail(String value) {
    state = state.copyWith(
      email: value,
      emailError: _validateEmail(value, state.login),
    );
  }

  void setUrl(String value) {
    state = state.copyWith(url: value, urlError: _validateUrl(value));
  }

  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  void setCustomFields(List<CustomFieldEntry> fields) {
    state = state.copyWith(customFields: fields);
  }

  void setNoteId(String? value) {
    state = state.copyWith(noteId: value);
  }

  void setOtp(String? otpId, String? otpName) {
    state = state.copyWith(otpId: otpId, otpName: otpName);
  }

  void setCategory(String? categoryId, String? categoryName) {
    state = state.copyWith(categoryId: categoryId, categoryName: categoryName);
  }

  void setIconRef(IconRefDto? iconRef) {
    state = state.copyWith(
      iconSource: iconRef?.sourceValue,
      iconValue: iconRef?.value,
    );
  }

  void setTags(List<String> tagIds, List<String> tagNames) {
    state = state.copyWith(tagIds: tagIds, tagNames: tagNames);
  }

  void setExpireAt(DateTime? value) {
    state = state.copyWith(expireAt: value);
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Название обязательно';
    }
    if (value.trim().length > 255) {
      return 'Название не должно превышать 255 символов';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Пароль обязателен';
    }
    return null;
  }

  String? _validateLogin(String login, String email) {
    if (login.trim().isEmpty && email.trim().isEmpty) {
      return 'Заполните логин или email';
    }
    return null;
  }

  String? _validateEmail(String email, String login) {
    if (email.trim().isEmpty && login.trim().isEmpty) {
      return 'Заполните email или логин';
    }

    if (email.trim().isNotEmpty && !_isValidEmail(email)) {
      return 'Неверный формат email';
    }

    return null;
  }

  String? _validateUrl(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    if (!_isValidUrl(value)) {
      return 'Неверный формат URL';
    }

    return null;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url.trim());
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

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

  Future<bool> save() async {
    if (!validateAll()) {
      logWarning('Form validation failed', tag: _logTag);
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      final repository = await ref.read(passwordRepositoryProvider.future);

      if (state.isEditMode && state.editingPasswordId != null) {
        await repository.update(
          PatchPasswordDto(
            item: VaultItemPatchDto(
              itemId: state.editingPasswordId!,
              name: FieldUpdate.set(state.name.trim()),
              description: FieldUpdate.set(
                state.description.trim().isEmpty ? null : state.description.trim(),
              ),
              categoryId: FieldUpdate.set(state.categoryId),
            ),
            password: PatchPasswordDataDto(
              login: FieldUpdate.set(
                state.login.trim().isEmpty ? null : state.login.trim(),
              ),
              email: FieldUpdate.set(
                state.email.trim().isEmpty ? null : state.email.trim(),
              ),
              password: FieldUpdate.set(state.password),
              url: FieldUpdate.set(
                state.url.trim().isEmpty ? null : state.url.trim(),
              ),
              expiresAt: FieldUpdate.set(state.expireAt),
            ),
            tags: FieldUpdate.set(state.tagIds),
          ),
        );

        await saveCustomFields(
          ref,
          state.editingPasswordId!,
          state.customFields,
        );
        // TODO: handle icon ref
        // TODO: handle OTP link

        logInfo('Password updated: ${state.editingPasswordId}', tag: _logTag);
        state = state.copyWith(isSaving: false, isSaved: true);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.password,
              entityId: state.editingPasswordId,
            );

        return true;
      } else {
        final id = await repository.create(
          CreatePasswordDto(
            item: VaultItemCreateDto(
              name: state.name.trim(),
              description: state.description.trim().isEmpty
                  ? null
                  : state.description.trim(),
              categoryId: state.categoryId,
            ),
            password: PasswordDataDto(
              login: state.login.trim().isEmpty ? null : state.login.trim(),
              email: state.email.trim().isEmpty ? null : state.email.trim(),
              password: state.password,
              url: state.url.trim().isEmpty ? null : state.url.trim(),
              expiresAt: state.expireAt,
            ),
          ),
        );

        // TODO: handle tags for create
        // TODO: handle icon ref
        // TODO: handle OTP link

        await saveCustomFields(ref, id, state.customFields);

        logInfo('Password created: $id', tag: _logTag);
        state = state.copyWith(isSaving: false, isSaved: true);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.password, entityId: id);

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

  void resetSaved() {
    state = state.copyWith(isSaved: false);
  }
}
