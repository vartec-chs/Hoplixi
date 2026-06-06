import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/ssh_key/ssh_key_items.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

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

    final repositories = await ref.read(vaultRepositories.future);
    final relationsService = await ref.read(
      vaultItemRelationsServiceProvider.future,
    );
    final viewResult = await repositories.sshKey.getViewById(id);

    final view = viewResult.getOrThrow().getOrNull();
    if (view == null) return const SshKeyFormState(isEditMode: false);

    final item = view.item;
    final ssh = view.sshKey;

    // Load tags
    final tagIdsResult = await relationsService.getTagIdsForItem(id);
    final tagIds = tagIdsResult.getOrThrow();
    final tagsResult = await repositories.tag.getTagsByIds(tagIds);
    final tags = tagsResult.getOrThrow();
    final tagNames = tags.map((t) => t.name).toList();

    // Load category name if exists
    String? categoryName;
    if (item.categoryId != null) {
      final catResult = await repositories.category.getCategory(
        item.categoryId!,
      );
      categoryName = catResult.getOrThrow().getOrNull()?.name;
    }

    final customFields = await loadCustomFields(ref, id);

    return SshKeyFormState(
      isEditMode: true,
      editingSshKeyId: id,
      name: item.name,
      publicKey: ssh.publicKey ?? '',
      privateKey: ssh.privateKey ?? '',
      keyType: ssh.keyType?.name ?? '',
      keyTypeOther: ssh.keyTypeOther ?? '',
      keySize: ssh.keySize,
      description: item.description ?? '',
      categoryId: item.categoryId,
      categoryName: categoryName,
      tagIds: tagIds,
      tagNames: tagNames,
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
  void setKeyTypeOther(String value) =>
      _update((s) => s.copyWith(keyTypeOther: value));
  void setKeySize(int? value) => _update((s) => s.copyWith(keySize: value));
  void setDescription(String value) =>
      _update((s) => s.copyWith(description: value));
  void setNote(String? noteId, String? noteName) =>
      _update((s) => s.copyWith(noteId: noteId, noteName: noteName));
  void setCategory(String? categoryId, String? categoryName) => _update(
    (s) => s.copyWith(categoryId: categoryId, categoryName: categoryName),
  );

  void setIconRef(IconRefDto? iconRef) => _update(
    (s) => s.copyWith(
      iconSource: iconRef?.iconSourceType.name,
      iconValue: iconRef?.iconValue,
    ),
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
      final services = await ref.read(vaultEntityServices.future);

      if (current.isEditMode && current.editingSshKeyId != null) {
        final res = await services.sshKey.update(
          PatchSshKeyDto(
            item: VaultItemPatchDto(
              itemId: current.editingSshKeyId!,
              name: FieldUpdate.set(current.name.trim()),
              description: FieldUpdate.set(clean(current.description)),
              categoryId: FieldUpdate.set(current.categoryId),
            ),
            sshKey: PatchSshKeyDataDto(
              publicKey: FieldUpdate.set(current.publicKey.trim()),
              privateKey: FieldUpdate.set(current.privateKey.trim()),
              keyType: FieldUpdate.set(
                current.keyType.isEmpty
                    ? null
                    : SshKeyType.values.byName(current.keyType),
              ),
              keyTypeOther: FieldUpdate.set(clean(current.keyTypeOther)),
              keySize: FieldUpdate.set(current.keySize),
            ),
            tags: FieldUpdate.set(current.tagIds),
          ),
        );

        res.getOrThrow();

        await saveCustomFields(
          ref,
          current.editingSshKeyId!,
          current.customFields,
        );

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.sshKey,
              entityId: current.editingSshKeyId,
            );
      } else {
        final res = await services.sshKey.create(
          CreateSshKeyDto(
            item: VaultItemCreateDto(
              name: current.name.trim(),
              description: clean(current.description),
              categoryId: current.categoryId,
            ),
            sshKey: SshKeyDataDto(
              publicKey: current.publicKey.trim(),
              privateKey: current.privateKey.trim(),
              keyType: current.keyType.isEmpty
                  ? null
                  : SshKeyType.values.byName(current.keyType),
              keyTypeOther: clean(current.keyTypeOther),
              keySize: current.keySize,
            ),
            tagIds: current.tagIds,
          ),
        );

        final id = res.getOrThrow();

        await saveCustomFields(ref, id, current.customFields);

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
