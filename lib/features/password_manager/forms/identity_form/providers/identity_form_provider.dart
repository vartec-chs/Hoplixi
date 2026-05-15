import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/providers/repository_providers.dart';

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

    final repository = await ref.read(identityRepositoryProvider.future);
    final view = await repository.getViewById(id);
    if (view == null) return const IdentityFormState(isEditMode: false);

    final item = view.item;
    final identity = view.identity;

    // TODO: handle tags properly
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
      tagIds: [],
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
  void setIdType(String v) => _update(
    (s) => s.copyWith(
      idType: v,
      idTypeError: _req(v, t.dashboard_forms.validation_required_type),
    ),
  );
  void setIdNumber(String v) => _update(
    (s) => s.copyWith(
      idNumber: v,
      idNumberError: _req(v, t.dashboard_forms.validation_required_number),
    ),
  );
  void setFullName(String v) => _update((s) => s.copyWith(fullName: v));
  void setDateOfBirth(String v) =>
      _update((s) => s.copyWith(dateOfBirth: v, dateOfBirthError: _dateErr(v)));
  void setPlaceOfBirth(String v) => _update((s) => s.copyWith(placeOfBirth: v));
  void setNationality(String v) => _update((s) => s.copyWith(nationality: v));
  void setIssuingAuthority(String v) =>
      _update((s) => s.copyWith(issuingAuthority: v));
  void setIssueDate(String v) =>
      _update((s) => s.copyWith(issueDate: v, issueDateError: _dateErr(v)));
  void setExpiryDate(String v) =>
      _update((s) => s.copyWith(expiryDate: v, expiryDateError: _dateErr(v)));
  void setMrz(String v) => _update((s) => s.copyWith(mrz: v));

  void setScanAttachment(String? id, String? name) => _update(
    (s) => s.copyWith(scanAttachmentId: id, scanAttachmentName: name),
  );

  void setPhotoAttachment(String? id, String? name) => _update(
    (s) => s.copyWith(photoAttachmentId: id, photoAttachmentName: name),
  );

  void setDescription(String v) => _update((s) => s.copyWith(description: v));
  void setVerified(bool v) => _update((s) => s.copyWith(verified: v));
  void setNote(String? id, String? name) =>
      _update((s) => s.copyWith(noteId: id, noteName: name));
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
      final repository = await ref.read(identityRepositoryProvider.future);

      if (c.isEditMode && c.editingIdentityId != null) {
        await repository.update(
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
              driverLicenseNumber: FieldUpdate.set(clean(c.driverLicenseNumber)),
            ),
            tags: FieldUpdate.set(c.tagIds),
          ),
        );

        await saveCustomFields(ref, c.editingIdentityId!, c.customFields);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.identity,
              entityId: c.editingIdentityId,
            );
      } else {
        final id = await repository.create(
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
          ),
        );

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
