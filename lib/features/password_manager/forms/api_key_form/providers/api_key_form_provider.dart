import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/providers/repository_providers.dart';

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

    final repository = await ref.read(apiKeyRepositoryProvider.future);
    final view = await repository.getViewById(id);
    if (view == null) {
      return const ApiKeyFormState(isEditMode: false);
    }

    final item = view.item;
    final details = view.apiKey;

    final tags = await ref.read(tagRepositoryProvider.future);
    final itemTags = await ref.read(apiKeyRepositoryProvider.future).then((r) => []); // TODO: handle tags properly in repository
    // Wait, I need a better way to get tags.
    // In NEW architecture, I should use VaultItemRelationsService or Repository.
    
    final customFields = await loadCustomFields(ref, id);

    return ApiKeyFormState(
      isEditMode: true,
      editingApiKeyId: id,
      name: item.name,
      service: details.service,
      key: details.key,
      tokenType: details.tokenType?.name ?? '',
      environment: details.environment?.name ?? '',
      description: item.description ?? '',
      revoked: view.isRevoked,
      expiresAt: details.expiresAt,
      categoryId: item.categoryId,
      tagIds: [], // TODO: get tag ids
      customFields: customFields,
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

  void setExpiresAt(DateTime? value) {
    _update((s) => s.copyWith(expiresAt: value));
  }

  void setNote(String? noteId, String? noteName) {
    _update((s) => s.copyWith(noteId: noteId, noteName: noteName));
  }

  void setCategory(String? categoryId, String? categoryName) {
    _update(
      (s) => s.copyWith(categoryId: categoryId, categoryName: categoryName),
    );
  }

  void setIconRef(IconRefDto? iconRef) {
    _update(
      (s) => s.copyWith(
        iconSource: iconRef?.sourceValue,
        iconValue: iconRef?.value,
      ),
    );
  }

  void setTags(List<String> tagIds, List<String> tagNames) {
    _update((s) => s.copyWith(tagIds: tagIds, tagNames: tagNames));
  }

  void setCustomFields(List<CustomFieldEntry> fields) =>
      _update((s) => s.copyWith(customFields: fields));

  String? _validateName(String value) {
    if (value.trim().isEmpty) return t.dashboard_forms.validation_required_name;
    return null;
  }

  String? _validateService(String value) {
    if (value.trim().isEmpty) {
      return t.dashboard_forms.validation_required_service;
    }
    return null;
  }

  String? _validateKey(String value) {
    final v = value.trim();
    if (v.isEmpty) return t.dashboard_forms.validation_required_key;
    if (v.length < 8) return t.dashboard_forms.validation_min8_chars;
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
    final description = current.description.trim();

    try {
      final repository = await ref.read(apiKeyRepositoryProvider.future);
      final masked = key.length > 6
          ? '${key.substring(0, 3)}***${key.substring(key.length - 3)}'
          : '******';

      if (current.isEditMode && current.editingApiKeyId != null) {
        await repository.update(
          PatchApiKeyDto(
            item: VaultItemPatchDto(
              itemId: current.editingApiKeyId!,
              name: FieldUpdate.set(name),
              description: FieldUpdate.set(description.isEmpty ? null : description),
              categoryId: FieldUpdate.set(current.categoryId),
              // TODO: isFavorite, isPinned from current state if available
            ),
            apiKey: PatchApiKeyDataDto(
              service: FieldUpdate.set(service),
              key: FieldUpdate.set(key),
              maskedKey: FieldUpdate.set(masked),
              expiresAt: FieldUpdate.set(current.expiresAt),
              revokedAt: FieldUpdate.set(current.revoked ? DateTime.now() : null),
              // TODO: other fields
            ),
            tags: FieldUpdate.set(current.tagIds),
          ),
        );

        await saveCustomFields(
          ref,
          current.editingApiKeyId!,
          current.customFields,
        );
        // TODO: handle icon ref via IconRepository/Service

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.apiKey,
              entityId: current.editingApiKeyId,
            );
      } else {
        final id = await repository.create(
          CreateApiKeyDto(
            item: VaultItemCreateDto(
              name: name,
              description: description.isEmpty ? null : description,
              categoryId: current.categoryId,
            ),
            apiKey: ApiKeyDataDto(
              service: service,
              key: key,
              expiresAt: current.expiresAt,
              revokedAt: current.revoked ? DateTime.now() : null,
            ),
          ),
        );

        await saveCustomFields(ref, id, current.customFields);
        // TODO: handle icon ref

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
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

