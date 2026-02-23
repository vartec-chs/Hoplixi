import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/generated/l10n.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../models/recovery_codes_form_state.dart';

final recoveryCodesFormProvider = AsyncNotifierProvider.autoDispose
    .family<RecoveryCodesFormNotifier, RecoveryCodesFormState, String?>(
      RecoveryCodesFormNotifier.new,
    );

class RecoveryCodesFormNotifier extends AsyncNotifier<RecoveryCodesFormState> {
  RecoveryCodesFormNotifier(this.recoveryCodesId);

  final String? recoveryCodesId;

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

    return RecoveryCodesFormState(
      isEditMode: true,
      editingRecoveryCodesId: id,
      name: item.name,
      codesBlob: data.codesBlob,
      codesCount: data.codesCount?.toString() ?? '',
      usedCount: data.usedCount?.toString() ?? '',
      perCodeStatus: data.perCodeStatus ?? '',
      generatedAt: data.generatedAt?.toIso8601String() ?? '',
      displayHint: data.displayHint ?? '',
      description: item.description ?? '',
      oneTime: data.oneTime,
      noteId: item.noteId,
      categoryId: item.categoryId,
      tagIds: tagIds,
      tagNames: tags.map((t) => t.name).toList(),
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
      nameError: value.trim().isEmpty ? S.current.validationRequiredName : null,
    ),
  );
  void setCodesBlob(String value) => _update(
    (s) => s.copyWith(
      codesBlob: value,
      codesBlobError: value.trim().isEmpty ? S.current.validationRequiredCodesBlob : null,
    ),
  );

  void setCodesCount(String value) {
    final v = value.trim();
    _update(
      (s) => s.copyWith(
        codesCount: value,
        codesCountError: v.isEmpty || int.tryParse(v) != null
            ? null : S.current.validationMustBeInteger,
      ),
    );
  }

  void setUsedCount(String value) {
    final v = value.trim();
    _update(
      (s) => s.copyWith(
        usedCount: value,
        usedCountError: v.isEmpty || int.tryParse(v) != null
            ? null : S.current.validationMustBeInteger,
      ),
    );
  }

  void setPerCodeStatus(String value) =>
      _update((s) => s.copyWith(perCodeStatus: value));
  void setGeneratedAt(String value) {
    final v = value.trim();
    _update(
      (s) => s.copyWith(
        generatedAt: value,
        generatedAtError: v.isEmpty || DateTime.tryParse(v) != null
            ? null
            : S.current.validationInvalidIso8601,
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

  bool validate() {
    final c = _current;
    final nameError = c.name.trim().isEmpty ? S.current.validationRequiredName : null;
    final codesBlobError = c.codesBlob.trim().isEmpty ? S.current.validationRequiredCodesBlob : null;
    final codesCountError =
        c.codesCount.trim().isEmpty || int.tryParse(c.codesCount.trim()) != null
        ? null : S.current.validationMustBeInteger;
    final usedCountError =
        c.usedCount.trim().isEmpty || int.tryParse(c.usedCount.trim()) != null
        ? null : S.current.validationMustBeInteger;
    final generatedAtError =
        c.generatedAt.trim().isEmpty ||
            DateTime.tryParse(c.generatedAt.trim()) != null
        ? null
        : S.current.validationInvalidIso8601;

    _update(
      (s) => s.copyWith(
        nameError: nameError,
        codesBlobError: codesBlobError,
        codesCountError: codesCountError,
        usedCountError: usedCountError,
        generatedAtError: generatedAtError,
      ),
    );

    return nameError == null &&
        codesBlobError == null &&
        codesCountError == null &&
        usedCountError == null &&
        generatedAtError == null;
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

    int? parseInt(String value) {
      final v = value.trim();
      if (v.isEmpty) return null;
      return int.tryParse(v);
    }

    try {
      final dao = await ref.read(recoveryCodesDaoProvider.future);

      if (c.isEditMode && c.editingRecoveryCodesId != null) {
        final updated = await dao.updateRecoveryCodes(
          c.editingRecoveryCodesId!,
          UpdateRecoveryCodesDto(
            name: c.name.trim(),
            codesBlob: c.codesBlob.trim(),
            codesCount: parseInt(c.codesCount),
            usedCount: parseInt(c.usedCount),
            perCodeStatus: clean(c.perCodeStatus),
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
            codesBlob: c.codesBlob.trim(),
            codesCount: parseInt(c.codesCount),
            usedCount: parseInt(c.usedCount),
            perCodeStatus: clean(c.perCodeStatus),
            generatedAt: parseDate(c.generatedAt),
            oneTime: c.oneTime,
            displayHint: clean(c.displayHint),
            description: clean(c.description),
            noteId: c.noteId,
            categoryId: c.categoryId,
            tagsIds: c.tagIds,
          ),
        );

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

