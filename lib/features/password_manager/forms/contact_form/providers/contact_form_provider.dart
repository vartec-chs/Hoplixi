import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/providers/repository_providers.dart';

import '../models/contact_form_state.dart';

final contactFormProvider = AsyncNotifierProvider.autoDispose
    .family<ContactFormNotifier, ContactFormState, String?>(
      ContactFormNotifier.new,
    );

class ContactFormNotifier extends AsyncNotifier<ContactFormState> {
  ContactFormNotifier(this.contactId);

  final String? contactId;

  @override
  Future<ContactFormState> build() async {
    if (contactId == null) {
      return const ContactFormState(isEditMode: false);
    }
    final id = contactId!;

    final repository = await ref.read(contactRepositoryProvider.future);
    final view = await repository.getViewById(id);
    if (view == null) {
      return const ContactFormState(isEditMode: false);
    }

    final item = view.item;
    final details = view.contact;

    // TODO: handle tags properly
    final customFields = await loadCustomFields(ref, id);

    return ContactFormState(
      isEditMode: true,
      editingContactId: id,
      name: item.name,
      firstName: details.firstName,
      middleName: details.middleName ?? '',
      lastName: details.lastName ?? '',
      phone: details.phone ?? '',
      email: details.email ?? '',
      company: details.company ?? '',
      jobTitle: details.jobTitle ?? '',
      address: details.address ?? '',
      website: details.website ?? '',
      birthday: details.birthday,
      isEmergencyContact: details.isEmergencyContact,
      description: item.description ?? '',
      categoryId: item.categoryId,
      tagIds: [],
      customFields: customFields,
    );
  }

  ContactFormState get _current => state.value ?? const ContactFormState();

  void _update(ContactFormState Function(ContactFormState value) cb) {
    state = AsyncData(cb(_current));
  }

  void setName(String value) {
    _update((s) => s.copyWith(name: value, nameError: _validateName(value)));
  }

  void setFirstName(String value) {
    _update(
      (s) => s.copyWith(firstName: value, firstNameError: _validateName(value)),
    );
  }

  void setMiddleName(String value) {
    _update((s) => s.copyWith(middleName: value));
  }

  void setLastName(String value) {
    _update((s) => s.copyWith(lastName: value));
  }

  void setPhone(String value) {
    _update((s) => s.copyWith(phone: value));
  }

  void setEmail(String value) {
    _update((s) => s.copyWith(email: value));
  }

  void setCompany(String value) {
    _update((s) => s.copyWith(company: value));
  }

  void setJobTitle(String value) {
    _update((s) => s.copyWith(jobTitle: value));
  }

  void setAddress(String value) {
    _update((s) => s.copyWith(address: value));
  }

  void setWebsite(String value) {
    _update((s) => s.copyWith(website: value));
  }

  void setBirthday(DateTime? value) {
    _update((s) => s.copyWith(birthday: value));
  }

  void setIsEmergencyContact(bool value) {
    _update((s) => s.copyWith(isEmergencyContact: value));
  }

  void setDescription(String value) {
    _update((s) => s.copyWith(description: value));
  }

  void setNoteId(String? value) {
    _update((s) => s.copyWith(noteId: value));
  }

  void setCategory(String? categoryId, String? categoryName) {
    _update(
      (s) => s.copyWith(categoryId: categoryId, categoryName: categoryName),
    );
  }

  void setIconRef(IconRefDto? iconRef) {
    _update(
      (s) => s.copyWith(
        iconSource: iconRef?.sourceValue,
        iconValue: iconRef?.value,
      ),
    );
  }

  void setTags(List<String> tagIds, List<String> tagNames) {
    _update((s) => s.copyWith(tagIds: tagIds, tagNames: tagNames));
  }

  void setCustomFields(List<CustomFieldEntry> fields) =>
      _update((s) => s.copyWith(customFields: fields));

  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'Обязательное поле';
    return null;
  }

  bool validate() {
    final current = _current;
    final nameError = _validateName(current.name);
    final firstNameError = _validateName(current.firstName);
    _update(
      (s) => s.copyWith(
        nameError: nameError,
        firstNameError: firstNameError,
      ),
    );

    return nameError == null && firstNameError == null;
  }

  Future<bool> save() async {
    if (!validate()) return false;

    final current = _current;
    _update((s) => s.copyWith(isSaving: true));

    try {
      final repository = await ref.read(contactRepositoryProvider.future);

      if (current.isEditMode && current.editingContactId != null) {
        await repository.update(
          PatchContactDto(
            item: VaultItemPatchDto(
              itemId: current.editingContactId!,
              name: FieldUpdate.set(current.name.trim()),
              description: FieldUpdate.set(
                current.description.trim().isEmpty
                    ? null
                    : current.description.trim(),
              ),
              categoryId: FieldUpdate.set(current.categoryId),
            ),
            contact: PatchContactDataDto(
              firstName: FieldUpdate.set(current.firstName.trim()),
              middleName: FieldUpdate.set(
                current.middleName.trim().isEmpty ? null : current.middleName.trim(),
              ),
              lastName: FieldUpdate.set(
                current.lastName.trim().isEmpty ? null : current.lastName.trim(),
              ),
              phone: FieldUpdate.set(
                current.phone.trim().isEmpty ? null : current.phone.trim(),
              ),
              email: FieldUpdate.set(
                current.email.trim().isEmpty ? null : current.email.trim(),
              ),
              company: FieldUpdate.set(
                current.company.trim().isEmpty ? null : current.company.trim(),
              ),
              jobTitle: FieldUpdate.set(
                current.jobTitle.trim().isEmpty ? null : current.jobTitle.trim(),
              ),
              address: FieldUpdate.set(
                current.address.trim().isEmpty ? null : current.address.trim(),
              ),
              website: FieldUpdate.set(
                current.website.trim().isEmpty ? null : current.website.trim(),
              ),
              birthday: FieldUpdate.set(current.birthday),
              isEmergencyContact: FieldUpdate.set(current.isEmergencyContact),
            ),
            tags: FieldUpdate.set(current.tagIds),
          ),
        );

        await saveCustomFields(
          ref,
          current.editingContactId!,
          current.customFields,
        );

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.contact,
              entityId: current.editingContactId,
            );
      } else {
        final id = await repository.create(
          CreateContactDto(
            item: VaultItemCreateDto(
              name: current.name.trim(),
              description: current.description.trim().isEmpty
                  ? null
                  : current.description.trim(),
              categoryId: current.categoryId,
            ),
            contact: ContactDataDto(
              firstName: current.firstName.trim(),
              middleName: current.middleName.trim().isEmpty
                  ? null
                  : current.middleName.trim(),
              lastName: current.lastName.trim().isEmpty
                  ? null
                  : current.lastName.trim(),
              phone: current.phone.trim().isEmpty ? null : current.phone.trim(),
              email: current.email.trim().isEmpty ? null : current.email.trim(),
              company: current.company.trim().isEmpty
                  ? null
                  : current.company.trim(),
              jobTitle: current.jobTitle.trim().isEmpty
                  ? null
                  : current.jobTitle.trim(),
              address: current.address.trim().isEmpty
                  ? null
                  : current.address.trim(),
              website: current.website.trim().isEmpty
                  ? null
                  : current.website.trim(),
              birthday: current.birthday,
              isEmergencyContact: current.isEmergencyContact,
            ),
          ),
        );

        await saveCustomFields(ref, id, current.customFields);

        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.contact, entityId: id);
      }

      _update((s) => s.copyWith(isSaving: false, isSaved: true));
      return true;
    } catch (_) {
      _update((s) => s.copyWith(isSaving: false));
      return false;
    }
  }

  void resetSaved() {
    _update((s) => s.copyWith(isSaved: false));
  }
}
