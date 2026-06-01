import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';

import '../models/identity_form_state.dart';

final identityFormProvider = AsyncNotifierProvider.autoDispose
    .family<IdentityFormNotifier, IdentityFormState, String?>(
      IdentityFormNotifier.new,
    );

class IdentityFormNotifier extends AsyncNotifier<IdentityFormState> {
  IdentityFormNotifier(this.identityId);

  final String? identityId;

  @override
  Future<IdentityFormState> build() async {
    if (identityId == null) return const IdentityFormState(isEditMode: false);
    final id = identityId!;

    final repositories = await ref.read(vaultRepositories.future);
    final relationsService = await ref.read(
      vaultItemRelationsServiceProvider.future,
    );
    final viewResult = await repositories.identity.getViewById(id);

    final view = viewResult.getOrThrow().getOrNull();
    if (view == null) return const IdentityFormState(isEditMode: false);

    final item = view.item;
    final identity = view.identity;

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

    return IdentityFormState(
      isEditMode: true,
      editingIdentityId: id,
      name: item.name,
      firstName: identity.firstName ?? '',
      middleName: identity.middleName ?? '',
      lastName: identity.lastName ?? '',
      displayName: identity.displayName ?? '',
      username: identity.username ?? '',
      email: identity.email ?? '',
      phone: identity.phone ?? '',
      address: identity.address ?? '',
      birthday: identity.birthday?.toIso8601String() ?? '',
      company: identity.company ?? '',
      jobTitle: identity.jobTitle ?? '',
      website: identity.website ?? '',
      taxId: identity.taxId ?? '',
      nationalId: identity.nationalId ?? '',
      passportNumber: identity.passportNumber ?? '',
      driverLicenseNumber: identity.driverLicenseNumber ?? '',
      description: item.description ?? '',
      categoryId: item.categoryId,
      categoryName: categoryName,
      tagIds: tagIds,
      tagNames: tagNames,
      customFields: customFields,
    );
  }

  IdentityFormState get _current => state.value ?? const IdentityFormState();

  void _update(IdentityFormState Function(IdentityFormState value) cb) {
    state = AsyncData(cb(_current));
  }

  String? _req(String v, String m) => v.trim().isEmpty ? m : null;
  String? _dateErr(String v) {
    final s = v.trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s) == null
        ? t.dashboard_forms.validation_invalid_iso8601
        : null;
  }

  void setName(String v) => _update(
    (s) => s.copyWith(
      name: v,
      nameError: _req(v, t.dashboard_forms.validation_required_name),
    ),
  );

  void setFirstName(String v) => _update((s) => s.copyWith(firstName: v));
  void setMiddleName(String v) => _update((s) => s.copyWith(middleName: v));
  void setLastName(String v) => _update((s) => s.copyWith(lastName: v));
  void setDisplayName(String v) => _update((s) => s.copyWith(displayName: v));
  void setUsername(String v) => _update((s) => s.copyWith(username: v));
  void setEmail(String v) => _update((s) => s.copyWith(email: v));
  void setPhone(String v) => _update((s) => s.copyWith(phone: v));
  void setAddress(String v) => _update((s) => s.copyWith(address: v));
  void setBirthday(String v) =>
      _update((s) => s.copyWith(birthday: v, birthdayError: _dateErr(v)));
  void setCompany(String v) => _update((s) => s.copyWith(company: v));
  void setJobTitle(String v) => _update((s) => s.copyWith(jobTitle: v));
  void setWebsite(String v) => _update((s) => s.copyWith(website: v));
  void setTaxId(String v) => _update((s) => s.copyWith(taxId: v));
  void setNationalId(String v) => _update((s) => s.copyWith(nationalId: v));
  void setPassportNumber(String v) =>
      _update((s) => s.copyWith(passportNumber: v));
  void setDriverLicenseNumber(String v) =>
      _update((s) => s.copyWith(driverLicenseNumber: v));

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
    final nameError = _req(c.name, t.dashboard_forms.validation_required_name);
    // TODO: proper validation

    _update((s) => s.copyWith(nameError: nameError));

    return nameError == null;
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

      if (c.isEditMode && c.editingIdentityId != null) {
        final res = await services.identity.update(
          PatchIdentityDto(
            item: VaultItemPatchDto(
              itemId: c.editingIdentityId!,
              name: FieldUpdate.set(c.name.trim()),
              description: FieldUpdate.set(clean(c.description)),
              categoryId: FieldUpdate.set(c.categoryId),
            ),
            identity: PatchIdentityDataDto(
              firstName: FieldUpdate.set(clean(c.firstName)),
              middleName: FieldUpdate.set(clean(c.middleName)),
              lastName: FieldUpdate.set(clean(c.lastName)),
              displayName: FieldUpdate.set(clean(c.displayName)),
              username: FieldUpdate.set(clean(c.username)),
              email: FieldUpdate.set(clean(c.email)),
              phone: FieldUpdate.set(clean(c.phone)),
              address: FieldUpdate.set(clean(c.address)),
              birthday: FieldUpdate.set(parseDate(c.birthday)),
              company: FieldUpdate.set(clean(c.company)),
              jobTitle: FieldUpdate.set(clean(c.jobTitle)),
              website: FieldUpdate.set(clean(c.website)),
              taxId: FieldUpdate.set(clean(c.taxId)),
              nationalId: FieldUpdate.set(clean(c.nationalId)),
              passportNumber: FieldUpdate.set(clean(c.passportNumber)),
              driverLicenseNumber: FieldUpdate.set(
                clean(c.driverLicenseNumber),
              ),
            ),
            tags: FieldUpdate.set(c.tagIds),
          ),
        );

        res.getOrThrow();

        await saveCustomFields(ref, c.editingIdentityId!, c.customFields);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.identity,
              entityId: c.editingIdentityId,
            );
      } else {
        final res = await services.identity.create(
          CreateIdentityDto(
            item: VaultItemCreateDto(
              name: c.name.trim(),
              description: clean(c.description),
              categoryId: c.categoryId,
            ),
            identity: IdentityDataDto(
              firstName: clean(c.firstName),
              middleName: clean(c.middleName),
              lastName: clean(c.lastName),
              displayName: clean(c.displayName),
              username: clean(c.username),
              email: clean(c.email),
              phone: clean(c.phone),
              address: clean(c.address),
              birthday: parseDate(c.birthday),
              company: clean(c.company),
              jobTitle: clean(c.jobTitle),
              website: clean(c.website),
              taxId: clean(c.taxId),
              nationalId: clean(c.nationalId),
              passportNumber: clean(c.passportNumber),
              driverLicenseNumber: clean(c.driverLicenseNumber),
            ),
            tagIds: c.tagIds,
          ),
        );

        final id = res.getOrThrow();

        await saveCustomFields(ref, id, c.customFields);
        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.identity, entityId: id);
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
