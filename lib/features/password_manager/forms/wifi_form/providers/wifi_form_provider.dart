import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';

import '../models/wifi_form_state.dart';

final wifiFormProvider = AsyncNotifierProvider.autoDispose
    .family<WifiFormNotifier, WifiFormState, String?>(WifiFormNotifier.new);

class WifiFormNotifier extends AsyncNotifier<WifiFormState> {
  WifiFormNotifier(this.wifiId);

  final String? wifiId;

  @override
  Future<WifiFormState> build() async {
    if (wifiId == null) return const WifiFormState(isEditMode: false);
    final id = wifiId!;

    final repositories = await ref.read(vaultRepositories.future);
    final relationsService = await ref.read(
      vaultItemRelationsServiceProvider.future,
    );
    final viewResult = await repositories.wifi.getViewById(id);

    final view = viewResult.getOrThrow().getOrNull();
    if (view == null) return const WifiFormState(isEditMode: false);

    final item = view.item;
    final wifi = view.wifi;

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

    return WifiFormState(
      isEditMode: true,
      editingWifiId: id,
      name: item.name,
      ssid: wifi.ssid,
      password: wifi.password ?? '',
      securityType: wifi.securityType?.name ?? '',
      securityTypeOther: wifi.securityTypeOther ?? '',
      encryption: wifi.encryption?.name ?? '',
      encryptionOther: wifi.encryptionOther ?? '',
      hiddenSsid: wifi.hiddenSsid,
      description: item.description ?? '',
      categoryId: item.categoryId,
      categoryName: categoryName,
      tagIds: tagIds,
      tagNames: tagNames,
      customFields: customFields,
    );
  }

  WifiFormState get _current => state.value ?? const WifiFormState();

  void _update(WifiFormState Function(WifiFormState value) cb) {
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

  void setSsid(String value) => _update(
    (s) => s.copyWith(
      ssid: value,
      ssidError: value.trim().isEmpty
          ? t.dashboard_forms.validation_required_ssid
          : null,
    ),
  );

  void applyImportedSsid(String value) {
    final normalized = value.trim();
    final shouldFillName = _current.name.trim().isEmpty;
    _update(
      (s) => s.copyWith(
        name: shouldFillName ? normalized : s.name,
        ssid: normalized,
        nameError: shouldFillName
            ? (normalized.isEmpty
                  ? t.dashboard_forms.validation_required_name
                  : null)
            : s.nameError,
        ssidError: normalized.isEmpty
            ? t.dashboard_forms.validation_required_ssid
            : null,
      ),
    );
  }

  void setPassword(String value) =>
      _update((s) => s.copyWith(password: value));
  void setSecurityType(String value) =>
      _update((s) => s.copyWith(securityType: value));
  void setSecurityTypeOther(String value) =>
      _update((s) => s.copyWith(securityTypeOther: value));
  void setEncryption(String value) =>
      _update((s) => s.copyWith(encryption: value));
  void setEncryptionOther(String value) =>
      _update((s) => s.copyWith(encryptionOther: value));
  void setHiddenSsid(bool value) =>
      _update((s) => s.copyWith(hiddenSsid: value));
  void setDescription(String value) =>
      _update((s) => s.copyWith(description: value));
  void setNote(String? noteId, String? noteName) =>
      _update((s) => s.copyWith(noteId: noteId, noteName: noteName));
  void setCategory(String? categoryId, String? categoryName) => _update(
    (s) => s.copyWith(categoryId: categoryId, categoryName: categoryName),
  );

  void setIconRef(IconRefDto? iconRef) => _update(
    (s) =>
        s.copyWith(iconSource: iconRef?.iconSourceType?.name, iconValue: iconRef?.iconValue),
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
    final ssidError = current.ssid.trim().isEmpty
        ? t.dashboard_forms.validation_required_ssid
        : null;

    _update(
      (s) => s.copyWith(nameError: nameError, ssidError: ssidError),
    );
    return nameError == null && ssidError == null;
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
      final priority = int.tryParse(current.priority.trim());

      if (current.isEditMode && current.editingWifiId != null) {
        final res = await services.wifi.update(
          PatchWifiDto(
            item: VaultItemPatchDto(
              itemId: current.editingWifiId!,
              name: FieldUpdate.set(current.name.trim()),
              description: FieldUpdate.set(clean(current.description)),
              categoryId: FieldUpdate.set(current.categoryId),
            ),
            wifi: PatchWifiDataDto(
              ssid: FieldUpdate.set(current.ssid.trim()),
              password: FieldUpdate.set(clean(current.password)),
              securityType: FieldUpdate.set(
                current.securityType.isEmpty
                    ? null
                    : WifiSecurityType.values.byName(current.securityType),
              ),
              securityTypeOther: FieldUpdate.set(
                clean(current.securityTypeOther),
              ),
              encryption: FieldUpdate.set(
                current.encryption.isEmpty
                    ? null
                    : WifiEncryptionType.values.byName(current.encryption),
              ),
              encryptionOther: FieldUpdate.set(clean(current.encryptionOther)),
              hiddenSsid: FieldUpdate.set(current.hiddenSsid),
            ),
            tags: FieldUpdate.set(current.tagIds),
          ),
        );

        res.getOrThrow();

        await saveCustomFields(
          ref,
          current.editingWifiId!,
          current.customFields,
        );

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.wifi,
              entityId: current.editingWifiId,
            );
      } else {
        final res = await services.wifi.create(
          CreateWifiDto(
            item: VaultItemCreateDto(
              name: current.name.trim(),
              description: clean(current.description),
              categoryId: current.categoryId,
            ),
            wifi: WifiDataDto(
              ssid: current.ssid.trim(),
              password: clean(current.password),
              securityType: current.securityType.isEmpty
                  ? null
                  : WifiSecurityType.values.byName(current.securityType),
              securityTypeOther: clean(current.securityTypeOther),
              encryption: current.encryption.isEmpty
                  ? null
                  : WifiEncryptionType.values.byName(current.encryption),
              encryptionOther: clean(current.encryptionOther),
              hiddenSsid: current.hiddenSsid,
            ),
            tagIds: current.tagIds,
          ),
        );

        final id = res.getOrThrow();

        await saveCustomFields(ref, id, current.customFields);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.wifi, entityId: id);
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

