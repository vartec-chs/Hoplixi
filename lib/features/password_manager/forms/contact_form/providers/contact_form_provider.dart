import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';

import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';

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

    final dao = await ref.read(contactDaoProvider.future);
    final row = await dao.getById(id);
    if (row == null) {
      return const ContactFormState(isEditMode: false);
    }

    final item = row.$1;
    final details = row.$2;

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    final tagIds = await vaultItemDao.getTagIds(id);
    final tagDao = await ref.read(tagDaoProvider.future);
    final tags = await tagDao.getTagsByIds(tagIds);
    final customFields = await loadCustomFields(ref, id);

    return ContactFormState(
      isEditMode: true,
      editingContactId: id,
      name: item.name,
      phone: details.phone ?? '',
      email: details.email ?? '',
      company: details.company ?? '',
      jobTitle: details.jobTitle ?? '',
      address: details.address ?? '',
      website: details.website ?? '',
      birthday: details.birthday,
      description: item.description ?? '',
      isEmergencyContact: details.isEmergencyContact,
      noteId: item.noteId,
      categoryId: item.categoryId,
      tagIds: tagIds,
      tagNames: tags.map((tag) => tag.name).toList(),
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

  void setPhone(String value) {
    _update((s) => s.copyWith(phone: value));
  }

  void setEmail(String value) {
    _update((s) => s.copyWith(email: value, emailError: _validateEmail(value)));
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

  void setDescription(String value) {
    _update((s) => s.copyWith(description: value));
  }

  void setEmergencyContact(bool value) {
    _update((s) => s.copyWith(isEmergencyContact: value));
  }

  void setNote(String? noteId, String? noteName) {
    _update((s) => s.copyWith(noteId: noteId, noteName: noteName));
  }

  void setCategory(String? categoryId, String? categoryName) {
    _update(
      (s) => s.copyWith(categoryId: categoryId, categoryName: categoryName),
    );
  }

  void setTags(List<String> tagIds, List<String> tagNames) {
    _update((s) => s.copyWith(tagIds: tagIds, tagNames: tagNames));
  }

  void setCustomFields(List<CustomFieldEntry> fields) {
    _update((s) => s.copyWith(customFields: fields));
  }

  void applyImportedContact({
    required String name,
    String? phone,
    String? email,
    String? company,
    String? jobTitle,
    String? address,
    String? website,
    DateTime? birthday,
  }) {
    _update(
      (s) => s.copyWith(
        name: name,
        phone: phone ?? '',
        email: email ?? '',
        company: company ?? '',
        jobTitle: jobTitle ?? '',
        address: address ?? '',
        website: website ?? '',
        birthday: birthday,
        nameError: _validateName(name),
        emailError: _validateEmail(email ?? ''),
      ),
    );
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) {
      return t.dashboard_forms.validation_required_contact_name;
    }
    return null;
  }

  String? _validateEmail(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
    if (!isValid) return t.dashboard_forms.validation_invalid_email;
    return null;
  }

  bool validate() {
    final current = _current;
    final nameError = _validateName(current.name);
    final emailError = _validateEmail(current.email);
    _update((s) => s.copyWith(nameError: nameError, emailError: emailError));

    return nameError == null && emailError == null;
  }

  Future<bool> save() async {
    if (!validate()) return false;

    final current = _current;
    _update((s) => s.copyWith(isSaving: true));

    String? norm(String value) {
      final v = value.trim();
      return v.isEmpty ? null : v;
    }

    try {
      final dao = await ref.read(contactDaoProvider.future);

      if (current.isEditMode && current.editingContactId != null) {
        final updated = await dao.updateContact(
          current.editingContactId!,
          UpdateContactDto(
            name: current.name.trim(),
            phone: norm(current.phone),
            email: norm(current.email),
            company: norm(current.company),
            jobTitle: norm(current.jobTitle),
            address: norm(current.address),
            website: norm(current.website),
            birthday: current.birthday,
            description: norm(current.description),
            noteId: current.noteId,
            categoryId: current.categoryId,
            isEmergencyContact: current.isEmergencyContact,
            tagsIds: current.tagIds,
          ),
        );

        if (!updated) {
          _update((s) => s.copyWith(isSaving: false));
          return false;
        }

        await saveCustomFields(
          ref,
          current.editingContactId!,
          current.customFields,
        );

        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityUpdate(
              EntityType.contact,
              entityId: current.editingContactId,
            );
      } else {
        final id = await dao.createContact(
          CreateContactDto(
            name: current.name.trim(),
            phone: norm(current.phone),
            email: norm(current.email),
            company: norm(current.company),
            jobTitle: norm(current.jobTitle),
            address: norm(current.address),
            website: norm(current.website),
            birthday: current.birthday,
            description: norm(current.description),
            noteId: current.noteId,
            categoryId: current.categoryId,
            isEmergencyContact: current.isEmergencyContact,
            tagsIds: current.tagIds,
          ),
        );

        await saveCustomFields(ref, id, current.customFields);
        ref
            .read(dataRefreshTriggerProvider.notifier)
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
