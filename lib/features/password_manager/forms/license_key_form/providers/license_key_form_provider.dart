import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/generated/l10n.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../models/license_key_form_state.dart';

final licenseKeyFormProvider = AsyncNotifierProvider.autoDispose
    .family<LicenseKeyFormNotifier, LicenseKeyFormState, String?>(
      LicenseKeyFormNotifier.new,
    );

class LicenseKeyFormNotifier extends AsyncNotifier<LicenseKeyFormState> {
  LicenseKeyFormNotifier(this.licenseKeyId);

  final String? licenseKeyId;

  @override
  Future<LicenseKeyFormState> build() async {
    if (licenseKeyId == null) {
      return const LicenseKeyFormState(isEditMode: false);
    }
    final id = licenseKeyId!;

    final dao = await ref.read(licenseKeyDaoProvider.future);
    final row = await dao.getById(id);
    if (row == null) return const LicenseKeyFormState(isEditMode: false);

    final item = row.$1;
    final license = row.$2;

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(id);
    final tagDao = await ref.read(tagDaoProvider.future);
    final tags = await tagDao.getTagsByIds(tagIds);

    return LicenseKeyFormState(
      isEditMode: true,
      editingLicenseKeyId: id,
      name: item.name,
      product: license.product,
      licenseKey: license.licenseKey,
      licenseType: license.licenseType ?? '',
      seats: license.seats?.toString() ?? '',
      maxActivations: license.maxActivations?.toString() ?? '',
      activatedOn: license.activatedOn?.toIso8601String() ?? '',
      purchaseDate: license.purchaseDate?.toIso8601String() ?? '',
      purchaseFrom: license.purchaseFrom ?? '',
      orderId: license.orderId ?? '',
      licenseFileId: license.licenseFileId ?? '',
      expiresAt: license.expiresAt?.toIso8601String() ?? '',
      supportContact: license.supportContact ?? '',
      description: item.description ?? '',
      noteId: item.noteId,
      categoryId: item.categoryId,
      tagIds: tagIds,
      tagNames: tags.map((t) => t.name).toList(),
    );
  }

  LicenseKeyFormState get _current =>
      state.value ?? const LicenseKeyFormState();

  void _update(LicenseKeyFormState Function(LicenseKeyFormState v) cb) {
    state = AsyncData(cb(_current));
  }

  String? _required(String value, String message) =>
      value.trim().isEmpty ? message : null;

  String? _intError(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v) == null ? S.current.validationMustBeInteger : null;
  }

  String? _dateError(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return DateTime.tryParse(v) == null ? S.current.validationInvalidIso8601 : null;
  }

  void setName(String v) => _update(
    (s) => s.copyWith(name: v, nameError: _required(v, S.current.validationRequiredName)),
  );
  void setProduct(String v) => _update(
    (s) => s.copyWith(
      product: v,
      productError: _required(v, S.current.validationRequiredProduct),
    ),
  );
  void setLicenseKey(String v) => _update(
    (s) => s.copyWith(
      licenseKey: v,
      licenseKeyError: _required(v, S.current.validationRequiredLicenseKey),
    ),
  );
  void setLicenseType(String v) => _update((s) => s.copyWith(licenseType: v));
  void setSeats(String v) =>
      _update((s) => s.copyWith(seats: v, seatsError: _intError(v)));
  void setMaxActivations(String v) => _update(
    (s) => s.copyWith(maxActivations: v, maxActivationsError: _intError(v)),
  );
  void setActivatedOn(String v) => _update(
    (s) => s.copyWith(activatedOn: v, activatedOnError: _dateError(v)),
  );
  void setPurchaseDate(String v) => _update(
    (s) => s.copyWith(purchaseDate: v, purchaseDateError: _dateError(v)),
  );
  void setPurchaseFrom(String v) => _update((s) => s.copyWith(purchaseFrom: v));
  void setOrderId(String v) => _update((s) => s.copyWith(orderId: v));
  void setLicenseFileId(String v) =>
      _update((s) => s.copyWith(licenseFileId: v));
  void setExpiresAt(String v) =>
      _update((s) => s.copyWith(expiresAt: v, expiresAtError: _dateError(v)));
  void setSupportContact(String v) =>
      _update((s) => s.copyWith(supportContact: v));
  void setDescription(String v) => _update((s) => s.copyWith(description: v));
  void setNote(String? id, String? name) =>
      _update((s) => s.copyWith(noteId: id, noteName: name));
  void setCategory(String? id, String? name) =>
      _update((s) => s.copyWith(categoryId: id, categoryName: name));
  void setTags(List<String> ids, List<String> names) =>
      _update((s) => s.copyWith(tagIds: ids, tagNames: names));

  bool validate() {
    final c = _current;
    final nameError = _required(c.name, S.current.validationRequiredName);
    final productError = _required(c.product, S.current.validationRequiredProduct);
    final licenseKeyError = _required(c.licenseKey, S.current.validationRequiredLicenseKey);
    final seatsError = _intError(c.seats);
    final maxActivationsError = _intError(c.maxActivations);
    final activatedOnError = _dateError(c.activatedOn);
    final purchaseDateError = _dateError(c.purchaseDate);
    final expiresAtError = _dateError(c.expiresAt);

    _update(
      (s) => s.copyWith(
        nameError: nameError,
        productError: productError,
        licenseKeyError: licenseKeyError,
        seatsError: seatsError,
        maxActivationsError: maxActivationsError,
        activatedOnError: activatedOnError,
        purchaseDateError: purchaseDateError,
        expiresAtError: expiresAtError,
      ),
    );

    return nameError == null &&
        productError == null &&
        licenseKeyError == null &&
        seatsError == null &&
        maxActivationsError == null &&
        activatedOnError == null &&
        purchaseDateError == null &&
        expiresAtError == null;
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
      final dao = await ref.read(licenseKeyDaoProvider.future);

      if (c.isEditMode && c.editingLicenseKeyId != null) {
        final updated = await dao.updateLicenseKey(
          c.editingLicenseKeyId!,
          UpdateLicenseKeyDto(
            name: c.name.trim(),
            product: c.product.trim(),
            licenseKey: c.licenseKey.trim(),
            licenseType: clean(c.licenseType),
            seats: parseInt(c.seats),
            maxActivations: parseInt(c.maxActivations),
            activatedOn: parseDate(c.activatedOn),
            purchaseDate: parseDate(c.purchaseDate),
            purchaseFrom: clean(c.purchaseFrom),
            orderId: clean(c.orderId),
            licenseFileId: clean(c.licenseFileId),
            expiresAt: parseDate(c.expiresAt),
            supportContact: clean(c.supportContact),
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
              EntityType.licenseKey,
              entityId: c.editingLicenseKeyId,
            );
      } else {
        final id = await dao.createLicenseKey(
          CreateLicenseKeyDto(
            name: c.name.trim(),
            product: c.product.trim(),
            licenseKey: c.licenseKey.trim(),
            licenseType: clean(c.licenseType),
            seats: parseInt(c.seats),
            maxActivations: parseInt(c.maxActivations),
            activatedOn: parseDate(c.activatedOn),
            purchaseDate: parseDate(c.purchaseDate),
            purchaseFrom: clean(c.purchaseFrom),
            orderId: clean(c.orderId),
            licenseFileId: clean(c.licenseFileId),
            expiresAt: parseDate(c.expiresAt),
            supportContact: clean(c.supportContact),
            description: clean(c.description),
            noteId: c.noteId,
            categoryId: c.categoryId,
            tagsIds: c.tagIds,
          ),
        );

        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.licenseKey, entityId: id);
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

