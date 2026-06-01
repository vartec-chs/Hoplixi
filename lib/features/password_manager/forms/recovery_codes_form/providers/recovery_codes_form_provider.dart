import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';

import '../models/recovery_codes_form_state.dart';

final recoveryCodesFormProvider = AsyncNotifierProvider.autoDispose
    .family<RecoveryCodesFormNotifier, RecoveryCodesFormState, String?>(
      RecoveryCodesFormNotifier.new,
    );

class RecoveryCodesFormNotifier extends AsyncNotifier<RecoveryCodesFormState> {
  RecoveryCodesFormNotifier(this.recoveryCodesId);

  final String? recoveryCodesId;

  /// Идентификаторы кодов, помеченных для удаления при следующем сохранении.
  final Set<int> _pendingDeleteIds = {};

  @override
  Future<RecoveryCodesFormState> build() async {
    if (recoveryCodesId == null) {
      return const RecoveryCodesFormState(isEditMode: false);
    }
    final id = recoveryCodesId!;

    final repositories = await ref.read(vaultRepositories.future);
    final relationsService = await ref.read(
      vaultItemRelationsServiceProvider.future,
    );
    final viewResult = await repositories.recoveryCodes.getViewById(id);

    final view = viewResult.getOrThrow().getOrNull();
    if (view == null) return const RecoveryCodesFormState(isEditMode: false);

    final item = view.item;
    final data = view.recoveryCodes;

    // Load tags
    final tagIdsResult = await relationsService.getTagIdsForItem(id);
    final tagIds = tagIdsResult.getOrThrow();
    final tagRecordsResult = await repositories.tag.getTagsByIds(tagIds);
    final tagRecords = tagRecordsResult.getOrThrow();

    final customFields = await loadCustomFields(ref, id);

    // Load category name if exists
    String? categoryName;
    if (item.categoryId != null) {
      final catResult = await repositories.category.getCategory(
        item.categoryId!,
      );
      categoryName = catResult.getOrThrow().getOrNull()?.name;
    }

    return RecoveryCodesFormState(
      isEditMode: true,
      editingRecoveryCodesId: id,
      name: item.name,
      generatedAt: data.generatedAt?.toIso8601String() ?? '',
      description: item.description ?? '',
      oneTime: data.oneTime,
      existingCodes: view.codes,
      categoryId: item.categoryId,
      categoryName: categoryName,
      tagIds: tagIds,
      tagNames: tagRecords.map((t) => t.name).toList(),
      customFields: customFields,
    );
  }

  RecoveryCodesFormState get _current =>
      state.value ?? const RecoveryCodesFormState();

  void _update(RecoveryCodesFormState Function(RecoveryCodesFormState v) cb) {
    state = AsyncData(cb(_current));
  }

  void setName(String value) => _update(
    (s) => s.copyWith(
      name: value,
      nameError: value.trim().isEmpty
          ? t.dashboard_forms.validation_required_name
          : null,
    ),
  );

  void setCodesInput(String value) =>
      _update((s) => s.copyWith(codesInput: value, codesInputError: null));

  void setGeneratedAt(String value) {
    final v = value.trim();
    _update(
      (s) => s.copyWith(
        generatedAt: value,
        generatedAtError: v.isEmpty || DateTime.tryParse(v) != null
            ? null
            : t.dashboard_forms.validation_invalid_iso8601,
      ),
    );
  }

  void setDisplayHint(String value) =>
      _update((s) => s.copyWith(displayHint: value));
  void setDescription(String value) =>
      _update((s) => s.copyWith(description: value));
  void setOneTime(bool value) => _update((s) => s.copyWith(oneTime: value));
  void setNote(String? id, String? name) =>
      _update((s) => s.copyWith(noteId: id, noteName: name));
  void setCategory(String? id, String? name) =>
      _update((s) => s.copyWith(categoryId: id, categoryName: name));
  void setTags(List<String> ids, List<String> names) =>
      _update((s) => s.copyWith(tagIds: ids, tagNames: names));

  void setCustomFields(List<CustomFieldEntry> fields) {
    _update((s) => s.copyWith(customFields: fields));
  }

  /// Пометить существующий код для удаления при сохранении.
  /// Код исчезает из списка немедленно; фактическое удаление — в [save].
  void markCodeForDeletion(int codeId) {
    _pendingDeleteIds.add(codeId);
    _update(
      (s) => s.copyWith(
        existingCodes: s.existingCodes.where((c) => c.id != codeId).toList(),
      ),
    );
  }

  bool validate() {
    final c = _current;
    final nameError = c.name.trim().isEmpty
        ? t.dashboard_forms.validation_required_name
        : null;

    // В режиме создания хотя бы один код обязателен
    final codesInputError = (!c.isEditMode && _parseCodes(c.codesInput).isEmpty)
        ? t.dashboard_forms.validation_at_least_one_code
        : null;

    final generatedAtError =
        c.generatedAt.trim().isEmpty ||
            DateTime.tryParse(c.generatedAt.trim()) != null
        ? null
        : t.dashboard_forms.validation_invalid_iso8601;

    _update(
      (s) => s.copyWith(
        nameError: nameError,
        codesInputError: codesInputError,
        generatedAtError: generatedAtError,
      ),
    );

    return nameError == null &&
        codesInputError == null &&
        generatedAtError == null;
  }

  List<String> _parseCodes(String input) {
    return input
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<bool> save() async {
    if (!validate()) return false;

    final c = _current;
    _update((s) => s.copyWith(isSaving: true));

    String? clean(String value) {
      final v = value.trim();
      return v.isEmpty ? null : v;
    }

    DateTime? parseDate(String value) {
      final v = value.trim();
      if (v.isEmpty) return null;
      return DateTime.tryParse(v);
    }

    try {
      final services = await ref.read(vaultEntityServices.future);
      final repositories = await ref.read(vaultRepositories.future);
      final parsedCodes = _parseCodes(c.codesInput);

      if (c.isEditMode && c.editingRecoveryCodesId != null) {
        // Удаляем коды, помеченные для удаления
        for (final codeId in _pendingDeleteIds) {
          await repositories.recoveryCodes.deleteCode(codeId);
        }
        _pendingDeleteIds.clear();

        if (parsedCodes.isNotEmpty) {
          await repositories.recoveryCodes.addCodes(
            itemId: c.editingRecoveryCodesId!,
            codes: parsedCodes
                .map((code) => RecoveryCodeValueDto(code: code))
                .toList(),
          );
        }

        final res = await services.recoveryCodes.update(
          PatchRecoveryCodesDto(
            item: VaultItemPatchDto(
              itemId: c.editingRecoveryCodesId!,
              name: FieldUpdate.set(c.name.trim()),
              description: FieldUpdate.set(clean(c.description)),
              categoryId: FieldUpdate.set(c.categoryId),
            ),
            recoveryCodes: PatchRecoveryCodesDataDto(
              generatedAt: FieldUpdate.set(parseDate(c.generatedAt)),
              oneTime: FieldUpdate.set(c.oneTime),
            ),
            tags: FieldUpdate.set(c.tagIds),
          ),
        );

        res.getOrThrow();

        await saveCustomFields(ref, c.editingRecoveryCodesId!, c.customFields);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.recoveryCodes,
              entityId: c.editingRecoveryCodesId,
            );
      } else {
        final res = await services.recoveryCodes.create(
          CreateRecoveryCodesDto(
            item: VaultItemCreateDto(
              name: c.name.trim(),
              description: clean(c.description),
              categoryId: c.categoryId,
            ),
            recoveryCodes: RecoveryCodesDataDto(
              generatedAt: parseDate(c.generatedAt),
              oneTime: c.oneTime,
            ),
            codes: parsedCodes
                .map((code) => RecoveryCodeValueDto(code: code))
                .toList(),
            tagIds: c.tagIds,
          ),
        );

        final id = res.getOrThrow();

        await saveCustomFields(ref, id, c.customFields);
        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.recoveryCodes, entityId: id);
      }

      _update((s) => s.copyWith(isSaving: false, isSaved: true));
      return true;
    } catch (_) {
      _update((s) => s.copyWith(isSaving: false));
      return false;
    }
  }

  void resetSaved() => _update((s) => s.copyWith(isSaved: false));
}
