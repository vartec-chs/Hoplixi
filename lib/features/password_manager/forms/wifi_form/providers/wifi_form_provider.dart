import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

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

    final dao = await ref.read(wifiDaoProvider.future);
    final row = await dao.getById(id);
    if (row == null) return const WifiFormState(isEditMode: false);

    final item = row.$1;
    final wifi = row.$2;

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(id);
    final tagDao = await ref.read(tagDaoProvider.future);
    final tags = await tagDao.getTagsByIds(tagIds);

    return WifiFormState(
      isEditMode: true,
      editingWifiId: id,
      name: item.name,
      ssid: wifi.ssid,
      password: wifi.password ?? '',
      security: wifi.security ?? '',
      hidden: wifi.hidden,
      eapMethod: wifi.eapMethod ?? '',
      username: wifi.username ?? '',
      identity: wifi.identity ?? '',
      domain: wifi.domain ?? '',
      lastConnectedBssid: wifi.lastConnectedBssid ?? '',
      priority: wifi.priority?.toString() ?? '',
      notes: wifi.notes ?? '',
      qrCodePayload: wifi.qrCodePayload ?? '',
      description: item.description ?? '',
      noteId: item.noteId,
      categoryId: item.categoryId,
      tagIds: tagIds,
      tagNames: tags.map((t) => t.name).toList(),
    );
  }

  WifiFormState get _current => state.value ?? const WifiFormState();

  void _update(WifiFormState Function(WifiFormState value) cb) {
    state = AsyncData(cb(_current));
  }

  void setName(String value) => _update(
    (s) => s.copyWith(
      name: value,
      nameError: value.trim().isEmpty ? 'Название обязательно' : null,
    ),
  );

  void setSsid(String value) => _update(
    (s) => s.copyWith(
      ssid: value,
      ssidError: value.trim().isEmpty ? 'SSID обязателен' : null,
    ),
  );

  void setPassword(String value) => _update((s) => s.copyWith(password: value));
  void setSecurity(String value) => _update((s) => s.copyWith(security: value));
  void setHidden(bool value) => _update((s) => s.copyWith(hidden: value));
  void setEapMethod(String value) =>
      _update((s) => s.copyWith(eapMethod: value));
  void setUsername(String value) => _update((s) => s.copyWith(username: value));
  void setIdentity(String value) => _update((s) => s.copyWith(identity: value));
  void setDomain(String value) => _update((s) => s.copyWith(domain: value));
  void setLastConnectedBssid(String value) =>
      _update((s) => s.copyWith(lastConnectedBssid: value));
  void setPriority(String value) {
    final v = value.trim();
    final err = v.isEmpty || int.tryParse(v) != null
        ? null
        : 'Нужно целое число';
    _update((s) => s.copyWith(priority: value, priorityError: err));
  }

  void setNotes(String value) => _update((s) => s.copyWith(notes: value));
  void setQrCodePayload(String value) =>
      _update((s) => s.copyWith(qrCodePayload: value));
  void setDescription(String value) =>
      _update((s) => s.copyWith(description: value));
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
    final ssidError = current.ssid.trim().isEmpty ? 'SSID обязателен' : null;
    final priorityError =
        current.priority.trim().isEmpty ||
            int.tryParse(current.priority.trim()) != null
        ? null
        : 'Нужно целое число';

    _update(
      (s) => s.copyWith(
        nameError: nameError,
        ssidError: ssidError,
        priorityError: priorityError,
      ),
    );
    return nameError == null && ssidError == null && priorityError == null;
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
      final dao = await ref.read(wifiDaoProvider.future);
      final priority = int.tryParse(current.priority.trim());

      if (current.isEditMode && current.editingWifiId != null) {
        final updated = await dao.updateWifi(
          current.editingWifiId!,
          UpdateWifiDto(
            name: current.name.trim(),
            ssid: current.ssid.trim(),
            password: clean(current.password),
            security: clean(current.security),
            hidden: current.hidden,
            eapMethod: clean(current.eapMethod),
            username: clean(current.username),
            identity: clean(current.identity),
            domain: clean(current.domain),
            lastConnectedBssid: clean(current.lastConnectedBssid),
            priority: priority,
            notes: clean(current.notes),
            qrCodePayload: clean(current.qrCodePayload),
            description: clean(current.description),
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
              EntityType.wifi,
              entityId: current.editingWifiId,
            );
      } else {
        final id = await dao.createWifi(
          CreateWifiDto(
            name: current.name.trim(),
            ssid: current.ssid.trim(),
            password: clean(current.password),
            security: clean(current.security),
            hidden: current.hidden,
            eapMethod: clean(current.eapMethod),
            username: clean(current.username),
            identity: clean(current.identity),
            domain: clean(current.domain),
            lastConnectedBssid: clean(current.lastConnectedBssid),
            priority: priority,
            notes: clean(current.notes),
            qrCodePayload: clean(current.qrCodePayload),
            description: clean(current.description),
            noteId: current.noteId,
            categoryId: current.categoryId,
            tagsIds: current.tagIds,
          ),
        );

        ref
            .read(dataRefreshTriggerProvider.notifier)
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
