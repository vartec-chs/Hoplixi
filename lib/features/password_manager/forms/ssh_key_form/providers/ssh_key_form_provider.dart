import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

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
      tagIds: tagIds,
      tagNames: tags.map((tag) => tag.name).toList(),
    );
  }

  SshKeyFormState get _current => state.value ?? const SshKeyFormState();

  void _update(SshKeyFormState Function(SshKeyFormState value) cb) {
    state = AsyncData(cb(_current));
  }

  void setName(String value) => _update(
    (s) => s.copyWith(
      name: value,
      nameError: value.trim().isEmpty ? 'Название обязательно' : null,
    ),
  );

  void setPublicKey(String value) => _update(
    (s) => s.copyWith(
      publicKey: value,
      publicKeyError: value.trim().isEmpty ? 'Public key обязателен' : null,
    ),
  );

  void setPrivateKey(String value) => _update(
    (s) => s.copyWith(
      privateKey: value,
      privateKeyError: value.trim().isEmpty ? 'Private key обязателен' : null,
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
  void setTags(List<String> tagIds, List<String> tagNames) =>
      _update((s) => s.copyWith(tagIds: tagIds, tagNames: tagNames));

  bool validate() {
    final current = _current;
    final nameError = current.name.trim().isEmpty
        ? 'Название обязательно'
        : null;
    final publicKeyError = current.publicKey.trim().isEmpty
        ? 'Public key обязателен'
        : null;
    final privateKeyError = current.privateKey.trim().isEmpty
        ? 'Private key обязателен'
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

        ref
            .read(dataRefreshTriggerProvider.notifier)
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

        ref
            .read(dataRefreshTriggerProvider.notifier)
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
