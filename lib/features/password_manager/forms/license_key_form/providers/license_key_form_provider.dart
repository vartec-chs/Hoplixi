import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/license_key/license_key_items.dart'
    show LicenseType;

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

    final repositories = await ref.read(vaultRepositories.future);
    final relationsService = await ref.read(
      vaultItemRelationsServiceProvider.future,
    );
    final viewResult = await repositories.licenseKey.getViewById(id);

    final view = viewResult.getOrThrow().getOrNull();
    if (view == null) return const LicenseKeyFormState(isEditMode: false);

    final item = view.item;
    final license = view.licenseKey;

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

    return LicenseKeyFormState(
      isEditMode: true,
      editingLicenseKeyId: id,
      name: item.name,
      productName: license.productName,
      vendor: license.vendor ?? '',
      licenseKey: license.licenseKey,
      licenseType: license.licenseType?.name,
      licenseTypeOther: license.licenseTypeOther ?? '',
      accountEmail: license.accountEmail ?? '',
      accountUsername: license.accountUsername ?? '',
      purchaseEmail: license.purchaseEmail ?? '',
      orderNumber: license.orderNumber ?? '',
      purchaseDate: license.purchaseDate?.toIso8601String() ?? '',
      purchasePrice: license.purchasePrice?.toString() ?? '',
      currency: license.currency ?? '',
      validFrom: license.validFrom?.toIso8601String() ?? '',
      validTo: license.validTo?.toIso8601String() ?? '',
      renewalDate: license.renewalDate?.toIso8601String() ?? '',
      seats: license.seats?.toString() ?? '',
      activationLimit: license.activationLimit?.toString() ?? '',
      activationsUsed: license.activationsUsed?.toString() ?? '',
      description: item.description ?? '',
      categoryId: item.categoryId,
      categoryName: categoryName,
      tagIds: tagIds,
      tagNames: tagNames,
      customFields: customFields,
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
    return int.tryParse(v) == null
        ? t.dashboard_forms.validation_must_be_integer
        : null;
  }

  String? _dateError(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return DateTime.tryParse(v) == null
        ? t.dashboard_forms.validation_invalid_iso8601
        : null;
  }

  void setName(String v) => _update(
    (s) => s.copyWith(
      name: v,
      nameError: _required(v, t.dashboard_forms.validation_required_name),
    ),
  );
  void setProductName(String v) => _update(
    (s) => s.copyWith(
      productName: v,
      productNameError: _required(
        v,
        t.dashboard_forms.validation_required_product,
      ),
    ),
  );
  void setVendor(String v) => _update((s) => s.copyWith(vendor: v));
  void setLicenseKey(String v) => _update(
    (s) => s.copyWith(
      licenseKey: v,
      licenseKeyError: _required(
        v,
        t.dashboard_forms.validation_required_license_key,
      ),
    ),
  );
  void setLicenseType(String? v) => _update((s) => s.copyWith(licenseType: v));
  void setLicenseTypeOther(String v) =>
      _update((s) => s.copyWith(licenseTypeOther: v));
  void setAccountEmail(String v) => _update((s) => s.copyWith(accountEmail: v));
  void setAccountUsername(String v) =>
      _update((s) => s.copyWith(accountUsername: v));
  void setPurchaseEmail(String v) =>
      _update((s) => s.copyWith(purchaseEmail: v));
  void setOrderNumber(String v) => _update((s) => s.copyWith(orderNumber: v));
  void setPurchasePrice(String v) =>
      _update((s) => s.copyWith(purchasePrice: v));
  void setCurrency(String v) => _update((s) => s.copyWith(currency: v));
  void setValidFrom(String v) =>
      _update((s) => s.copyWith(validFrom: v, validFromError: _dateError(v)));
  void setValidTo(String v) =>
      _update((s) => s.copyWith(validTo: v, validToError: _dateError(v)));
  void setRenewalDate(String v) => _update(
    (s) => s.copyWith(renewalDate: v, renewalDateError: _dateError(v)),
  );
  void setSeats(String v) =>
      _update((s) => s.copyWith(seats: v, seatsError: _intError(v)));
  void setActivationLimit(String v) => _update(
    (s) => s.copyWith(activationLimit: v, activationLimitError: _intError(v)),
  );
  void setActivationsUsed(String v) => _update(
    (s) => s.copyWith(activationsUsed: v, activationsUsedError: _intError(v)),
  );
  void setPurchaseDate(String v) => _update(
    (s) => s.copyWith(purchaseDate: v, purchaseDateError: _dateError(v)),
  );
  void setDescription(String v) => _update((s) => s.copyWith(description: v));
  void setCategory(String? id, String? name) =>
      _update((s) => s.copyWith(categoryId: id, categoryName: name));
  void setTags(List<String> ids, List<String> names) =>
      _update((s) => s.copyWith(tagIds: ids, tagNames: names));

  void setCustomFields(List<CustomFieldEntry> fields) {
    _update((s) => s.copyWith(customFields: fields));
  }

  bool validate() {
    final c = _current;
    final nameError = _required(
      c.name,
      t.dashboard_forms.validation_required_name,
    );
    final productNameError = _required(
      c.productName,
      t.dashboard_forms.validation_required_product,
    );
    final licenseKeyError = _required(
      c.licenseKey,
      t.dashboard_forms.validation_required_license_key,
    );
    final seatsError = _intError(c.seats);
    final activationLimitError = _intError(c.activationLimit);
    final activationsUsedError = _intError(c.activationsUsed);
    final purchaseDateError = _dateError(c.purchaseDate);
    final validFromError = _dateError(c.validFrom);
    final validToError = _dateError(c.validTo);
    final renewalDateError = _dateError(c.renewalDate);

    _update(
      (s) => s.copyWith(
        nameError: nameError,
        productNameError: productNameError,
        licenseKeyError: licenseKeyError,
        seatsError: seatsError,
        activationLimitError: activationLimitError,
        activationsUsedError: activationsUsedError,
        purchaseDateError: purchaseDateError,
        validFromError: validFromError,
        validToError: validToError,
        renewalDateError: renewalDateError,
      ),
    );

    return nameError == null &&
        productNameError == null &&
        licenseKeyError == null &&
        seatsError == null &&
        activationLimitError == null &&
        activationsUsedError == null &&
        purchaseDateError == null &&
        validFromError == null &&
        validToError == null &&
        renewalDateError == null;
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

    double? parseDouble(String value) {
      final v = value.trim();
      if (v.isEmpty) return null;
      return double.tryParse(v);
    }

    LicenseType? parseLicenseType(String? value) {
      if (value == null || value.isEmpty) return null;
      return LicenseType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => LicenseType.other,
      );
    }

    try {
      final services = await ref.read(vaultEntityServices.future);

      if (c.isEditMode && c.editingLicenseKeyId != null) {
        final res = await services.licenseKey.update(
          PatchLicenseKeyDto(
            item: VaultItemPatchDto(
              itemId: c.editingLicenseKeyId!,
              name: FieldUpdate.set(c.name.trim()),
              description: FieldUpdate.set(clean(c.description)),
              categoryId: FieldUpdate.set(c.categoryId),
            ),
            licenseKey: PatchLicenseKeyDataDto(
              productName: FieldUpdate.set(c.productName.trim()),
              vendor: FieldUpdate.set(clean(c.vendor)),
              licenseKey: FieldUpdate.set(c.licenseKey.trim()),
              licenseType: FieldUpdate.set(parseLicenseType(c.licenseType)),
              licenseTypeOther: FieldUpdate.set(clean(c.licenseTypeOther)),
              accountEmail: FieldUpdate.set(clean(c.accountEmail)),
              accountUsername: FieldUpdate.set(clean(c.accountUsername)),
              purchaseEmail: FieldUpdate.set(clean(c.purchaseEmail)),
              orderNumber: FieldUpdate.set(clean(c.orderNumber)),
              purchaseDate: FieldUpdate.set(parseDate(c.purchaseDate)),
              purchasePrice: FieldUpdate.set(parseDouble(c.purchasePrice)),
              currency: FieldUpdate.set(clean(c.currency)),
              validFrom: FieldUpdate.set(parseDate(c.validFrom)),
              validTo: FieldUpdate.set(parseDate(c.validTo)),
              renewalDate: FieldUpdate.set(parseDate(c.renewalDate)),
              seats: FieldUpdate.set(parseInt(c.seats)),
              activationLimit: FieldUpdate.set(parseInt(c.activationLimit)),
              activationsUsed: FieldUpdate.set(parseInt(c.activationsUsed)),
            ),
            tags: FieldUpdate.set(c.tagIds),
          ),
        );

        res.getOrThrow();

        await saveCustomFields(ref, c.editingLicenseKeyId!, c.customFields);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.licenseKey,
              entityId: c.editingLicenseKeyId,
            );
      } else {
        final res = await services.licenseKey.create(
          CreateLicenseKeyDto(
            item: VaultItemCreateDto(
              name: c.name.trim(),
              description: clean(c.description),
              categoryId: c.categoryId,
            ),
            licenseKey: LicenseKeyDataDto(
              productName: c.productName.trim(),
              vendor: clean(c.vendor),
              licenseKey: c.licenseKey.trim(),
              licenseType: parseLicenseType(c.licenseType),
              licenseTypeOther: clean(c.licenseTypeOther),
              accountEmail: clean(c.accountEmail),
              accountUsername: clean(c.accountUsername),
              purchaseEmail: clean(c.purchaseEmail),
              orderNumber: clean(c.orderNumber),
              purchaseDate: parseDate(c.purchaseDate),
              purchasePrice: parseDouble(c.purchasePrice),
              currency: clean(c.currency),
              validFrom: parseDate(c.validFrom),
              validTo: parseDate(c.validTo),
              renewalDate: parseDate(c.renewalDate),
              seats: parseInt(c.seats),
              activationLimit: parseInt(c.activationLimit),
              activationsUsed: parseInt(c.activationsUsed),
            ),
            tagIds: c.tagIds,
          ),
        );

        final id = res.getOrThrow();

        await saveCustomFields(ref, id, c.customFields);
        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
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
