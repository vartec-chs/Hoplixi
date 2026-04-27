import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/new/providers/dao_providers.dart';

import 'package:hoplixi/shared/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/shared/custom_fields/models/custom_field_entry.dart';

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

    final dao = await ref.read(recoveryCodesDaoProvider.future);
    final row = await dao.getById(id);
    if (row == null) return const RecoveryCodesFormState(isEditMode: false);

    final item = row.$1;
    final data = row.$2;

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(id);
    final tagDao = await ref.read(tagDaoProvider.future);
    final tags = await tagDao.getTagsByIds(tagIds);
    final customFields = await loadCustomFields(ref, id);

    // Загружаем существующие коды
    final codesRaw = await dao.getCodesForItem(id);
    final existingCodes = codesRaw
        .map(
          (c) => RecoveryCodeItemDto(
            id: c.id,
            itemId: c.itemId,
            code: c.code,
            used: c.used,
            usedAt: c.usedAt,
            position: c.position,
          ),
        )
        .toList();

    return RecoveryCodesFormState(
      isEditMode: true,
      editingRecoveryCodesId: id,
      name: item.name,
      generatedAt: data.generatedAt?.toIso8601String() ?? '',
      displayHint: data.displayHint ?? '',
      description: item.description ?? '',
      oneTime: data.oneTime,
      existingCodes: existingCodes,
      noteId: item.noteId,
      categoryId: item.categoryId,
      tagIds: tagIds,
      tagNames: tags.map((t) => t.name).toList(),
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
      final dao = await ref.read(recoveryCodesDaoProvider.future);
      final parsedCodes = _parseCodes(c.codesInput);

      if (c.isEditMode && c.editingRecoveryCodesId != null) {
        // Удаляем коды, помеченные для удаления
        for (final codeId in _pendingDeleteIds) {
          await dao.deleteCode(codeId);
        }
        _pendingDeleteIds.clear();

        final updated = await dao.updateRecoveryCodes(
          c.editingRecoveryCodesId!,
          UpdateRecoveryCodesDto(
            name: c.name.trim(),
            newCodes: parsedCodes.isEmpty ? null : parsedCodes,
            generatedAt: parseDate(c.generatedAt),
            oneTime: c.oneTime,
            displayHint: clean(c.displayHint),
            description: clean(c.description),
            noteId: c.noteId,
            categoryId: c.categoryId,
            tagsIds: c.tagIds,
          ),
        );

        if (!updated) {
          _update((s) => s.copyWith(isSaving: false));
          return false;
        }

        await saveCustomFields(ref, c.editingRecoveryCodesId!, c.customFields);

        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.recoveryCodes,
              entityId: c.editingRecoveryCodesId,
            );
      } else {
        final id = await dao.createRecoveryCodes(
          CreateRecoveryCodesDto(
            name: c.name.trim(),
            codes: parsedCodes,
            generatedAt: parseDate(c.generatedAt),
            oneTime: c.oneTime,
            displayHint: clean(c.displayHint),
            description: clean(c.description),
            noteId: c.noteId,
            categoryId: c.categoryId,
            tagsIds: c.tagIds,
          ),
        );

        await saveCustomFields(ref, id, c.customFields);
        ref
            .read(dataRefreshTriggerProvider.notifier)
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
