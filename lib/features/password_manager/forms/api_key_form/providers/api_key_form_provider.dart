import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/generated/l10n.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../models/api_key_form_state.dart';

final apiKeyFormProvider = AsyncNotifierProvider.autoDispose
    .family<ApiKeyFormNotifier, ApiKeyFormState, String?>(
      ApiKeyFormNotifier.new,
    );

class ApiKeyFormNotifier extends AsyncNotifier<ApiKeyFormState> {
  ApiKeyFormNotifier(this.apiKeyId);

  final String? apiKeyId;

  @override
  Future<ApiKeyFormState> build() async {
    if (apiKeyId == null) {
      return const ApiKeyFormState(isEditMode: false);
    }
    final id = apiKeyId!;

    final dao = await ref.read(apiKeyDaoProvider.future);
    final row = await dao.getById(id);
    if (row == null) {
      return const ApiKeyFormState(isEditMode: false);
    }

    final item = row.$1;
    final details = row.$2;

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(id);
    final tagDao = await ref.read(tagDaoProvider.future);
    final tags = await tagDao.getTagsByIds(tagIds);

    return ApiKeyFormState(
      isEditMode: true,
      editingApiKeyId: id,
      name: item.name,
      service: details.service,
      key: details.key,
      tokenType: details.tokenType ?? '',
      environment: details.environment ?? '',
      description: item.description ?? '',
      revoked: details.revoked,
      noteId: item.noteId,
      categoryId: item.categoryId,
      tagIds: tagIds,
      tagNames: tags.map((tag) => tag.name).toList(),
    );
  }

  ApiKeyFormState get _current => state.value ?? const ApiKeyFormState();

  void _update(ApiKeyFormState Function(ApiKeyFormState value) cb) {
    state = AsyncData(cb(_current));
  }

  void setName(String value) {
    _update((s) => s.copyWith(name: value, nameError: _validateName(value)));
  }

  void setService(String value) {
    _update(
      (s) => s.copyWith(service: value, serviceError: _validateService(value)),
    );
  }

  void setKey(String value) {
    _update((s) => s.copyWith(key: value, keyError: _validateKey(value)));
  }

  void setTokenType(String value) {
    _update((s) => s.copyWith(tokenType: value));
  }

  void setEnvironment(String value) {
    _update((s) => s.copyWith(environment: value));
  }

  void setDescription(String value) {
    _update((s) => s.copyWith(description: value));
  }

  void setRevoked(bool value) {
    _update((s) => s.copyWith(revoked: value));
  }

  void setNote(String? noteId, String? noteName) {
    _update((s) => s.copyWith(noteId: noteId, noteName: noteName));
  }

  void setCategory(String? categoryId, String? categoryName) {
    _update(
      (s) => s.copyWith(categoryId: categoryId, categoryName: categoryName),
    );
  }

  void setTags(List<String> tagIds, List<String> tagNames) {
    _update((s) => s.copyWith(tagIds: tagIds, tagNames: tagNames));
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) return S.current.validationRequiredName;
    return null;
  }

  String? _validateService(String value) {
    if (value.trim().isEmpty) return S.current.validationRequiredService;
    return null;
  }

  String? _validateKey(String value) {
    final v = value.trim();
    if (v.isEmpty) return S.current.validationRequiredKey;
    if (v.length < 8) return S.current.validationMin8Chars;
    return null;
  }

  bool validate() {
    final current = _current;
    final nameError = _validateName(current.name);
    final serviceError = _validateService(current.service);
    final keyError = _validateKey(current.key);
    _update(
      (s) => s.copyWith(
        nameError: nameError,
        serviceError: serviceError,
        keyError: keyError,
      ),
    );

    return nameError == null && serviceError == null && keyError == null;
  }

  Future<bool> save() async {
    if (!validate()) return false;

    final current = _current;
    _update((s) => s.copyWith(isSaving: true));

    final name = current.name.trim();
    final service = current.service.trim();
    final key = current.key.trim();
    final tokenType = current.tokenType.trim();
    final environment = current.environment.trim();
    final description = current.description.trim();

    try {
      final dao = await ref.read(apiKeyDaoProvider.future);
      final masked = key.length > 6
          ? '${key.substring(0, 3)}***${key.substring(key.length - 3)}'
          : '******';

      if (current.isEditMode && current.editingApiKeyId != null) {
        final updated = await dao.updateApiKey(
          current.editingApiKeyId!,
          UpdateApiKeyDto(
            name: name,
            service: service,
            key: key,
            description: description.isEmpty ? null : description,
            tokenType: tokenType.isEmpty ? null : tokenType,
            environment: environment.isEmpty ? null : environment,
            noteId: current.noteId,
            categoryId: current.categoryId,
            revoked: current.revoked,
            tagsIds: current.tagIds,
            maskedKey: masked,
          ),
        );

        if (!updated) {
          _update((s) => s.copyWith(isSaving: false));
          return false;
        }

        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.apiKey,
              entityId: current.editingApiKeyId,
            );
      } else {
        final id = await dao.createApiKey(
          CreateApiKeyDto(
            name: name,
            service: service,
            key: key,
            description: description.isEmpty ? null : description,
            tokenType: tokenType.isEmpty ? null : tokenType,
            environment: environment.isEmpty ? null : environment,
            noteId: current.noteId,
            categoryId: current.categoryId,
            revoked: current.revoked,
            tagsIds: current.tagIds,
            maskedKey: masked,
          ),
        );

        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.apiKey, entityId: id);
      }

      _update((s) => s.copyWith(isSaving: false, isSaved: true));
      return true;
    } catch (_) {
      _update((s) => s.copyWith(isSaving: false));
      return false;
    }
  }

  void resetSaved() {
    _update((s) => s.copyWith(isSaved: false));
  }
}

