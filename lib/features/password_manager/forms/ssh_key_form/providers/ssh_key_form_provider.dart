import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard_v2/dashboard_v2.dart';
import 'package:hoplixi/features/password_manager/dashboard_v2/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';

import '../models/ssh_key_form_state.dart';

final sshKeyFormProvider = AsyncNotifierProvider.autoDispose
    .family<SshKeyFormNotifier, SshKeyFormState, String?>(
      SshKeyFormNotifier.new,
    );

class SshKeyFormNotifier extends AsyncNotifier<SshKeyFormState> {
  SshKeyFormNotifier(this.sshKeyId);

  final String? sshKeyId;

  @override
  Future<SshKeyFormState> build() async {
    if (sshKeyId == null) return const SshKeyFormState(isEditMode: false);
    final id = sshKeyId!;

    final dao = await ref.read(sshKeyDaoProvider.future);
    final row = await dao.getById(id);
    if (row == null) return const SshKeyFormState(isEditMode: false);

    final item = row.$1;
    final ssh = row.$2;

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(id);
    final tagDao = await ref.read(tagDaoProvider.future);
    final tags = await tagDao.getTagsByIds(tagIds);
    final customFields = await loadCustomFields(ref, id);

    return SshKeyFormState(
      isEditMode: true,
      editingSshKeyId: id,
      name: item.name,
      publicKey: ssh.publicKey,
      privateKey: ssh.privateKey,
      keyType: ssh.keyType ?? '',
      fingerprint: ssh.fingerprint ?? '',
      usage: ssh.usage ?? '',
      description: item.description ?? '',
      addedToAgent: ssh.addedToAgent,
      noteId: item.noteId,
      categoryId: item.categoryId,
      iconSource: item.iconSource,
      iconValue: item.iconValue,
      tagIds: tagIds,
      tagNames: tags.map((tag) => tag.name).toList(),
      customFields: customFields,
    );
  }

  SshKeyFormState get _current => state.value ?? const SshKeyFormState();

  void _update(SshKeyFormState Function(SshKeyFormState value) cb) {
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

  void setPublicKey(String value) => _update(
    (s) => s.copyWith(
      publicKey: value,
      publicKeyError: value.trim().isEmpty
          ? t.dashboard_forms.validation_required_public_key
          : null,
    ),
  );

  void setPrivateKey(String value) => _update(
    (s) => s.copyWith(
      privateKey: value,
      privateKeyError: value.trim().isEmpty
          ? t.dashboard_forms.validation_required_private_key
          : null,
    ),
  );

  void setKeyType(String value) => _update((s) => s.copyWith(keyType: value));
  void setFingerprint(String value) =>
      _update((s) => s.copyWith(fingerprint: value));
  void setUsage(String value) => _update((s) => s.copyWith(usage: value));
  void setDescription(String value) =>
      _update((s) => s.copyWith(description: value));
  void setAddedToAgent(bool value) =>
      _update((s) => s.copyWith(addedToAgent: value));
  void setNote(String? noteId, String? noteName) =>
      _update((s) => s.copyWith(noteId: noteId, noteName: noteName));
  void setCategory(String? categoryId, String? categoryName) => _update(
    (s) => s.copyWith(categoryId: categoryId, categoryName: categoryName),
  );

  void setIconRef(IconRefDto? iconRef) => _update(
    (s) =>
        s.copyWith(iconSource: iconRef?.sourceValue, iconValue: iconRef?.value),
  );

  void setTags(List<String> tagIds, List<String> tagNames) =>
      _update((s) => s.copyWith(tagIds: tagIds, tagNames: tagNames));

  void setCustomFields(List<CustomFieldEntry> fields) {
    _update((s) => s.copyWith(customFields: fields));
  }

  bool validate() {
    final current = _current;
    final nameError = current.name.trim().isEmpty
        ? t.dashboard_forms.validation_required_name
        : null;
    final publicKeyError = current.publicKey.trim().isEmpty
        ? t.dashboard_forms.validation_required_public_key
        : null;
    final privateKeyError = current.privateKey.trim().isEmpty
        ? t.dashboard_forms.validation_required_private_key
        : null;

    _update(
      (s) => s.copyWith(
        nameError: nameError,
        publicKeyError: publicKeyError,
        privateKeyError: privateKeyError,
      ),
    );
    return nameError == null &&
        publicKeyError == null &&
        privateKeyError == null;
  }

  Future<bool> save() async {
    if (!validate()) return false;

    final current = _current;
    _update((s) => s.copyWith(isSaving: true));

    String? clean(String value) {
      final v = value.trim();
      return v.isEmpty ? null : v;
    }

    try {
      final dao = await ref.read(sshKeyDaoProvider.future);

      if (current.isEditMode && current.editingSshKeyId != null) {
        final updated = await dao.updateSshKey(
          current.editingSshKeyId!,
          UpdateSshKeyDto(
            name: current.name.trim(),
            publicKey: current.publicKey.trim(),
            privateKey: current.privateKey.trim(),
            keyType: clean(current.keyType),
            fingerprint: clean(current.fingerprint),
            usage: clean(current.usage),
            description: clean(current.description),
            addedToAgent: current.addedToAgent,
            noteId: current.noteId,
            categoryId: current.categoryId,
            tagsIds: current.tagIds,
          ),
        );

        if (!updated) {
          _update((s) => s.copyWith(isSaving: false));
          return false;
        }

        await saveCustomFields(
          ref,
          current.editingSshKeyId!,
          current.customFields,
        );
        final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
        await vaultItemDao.setIconRef(
          current.editingSshKeyId!,
          IconRefDto.fromFields(
            iconSource: current.iconSource,
            iconValue: current.iconValue,
          ),
        );

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.sshKey,
              entityId: current.editingSshKeyId,
            );
      } else {
        final id = await dao.createSshKey(
          CreateSshKeyDto(
            name: current.name.trim(),
            publicKey: current.publicKey.trim(),
            privateKey: current.privateKey.trim(),
            keyType: clean(current.keyType),
            fingerprint: clean(current.fingerprint),
            usage: clean(current.usage),
            description: clean(current.description),
            addedToAgent: current.addedToAgent,
            noteId: current.noteId,
            categoryId: current.categoryId,
            tagsIds: current.tagIds,
          ),
        );

        await saveCustomFields(ref, id, current.customFields);
        final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
        await vaultItemDao.setIconRef(
          id,
          IconRefDto.fromFields(
            iconSource: current.iconSource,
            iconValue: current.iconValue,
          ),
        );
        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.sshKey, entityId: id);
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
