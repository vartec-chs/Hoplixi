import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/shared/custom_fields/widgets/custom_fields_editor.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/contact_form_provider.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({super.key, this.contactId});

  final String? contactId;

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _companyController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _addressController;
  late final TextEditingController _websiteController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _companyController = TextEditingController();
    _jobTitleController = TextEditingController();
    _addressController = TextEditingController();
    _websiteController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref
        .read(contactFormProvider(widget.contactId).notifier)
        .save();

    if (!mounted) return;

    if (!success) {
      Toaster.error(
        title: context.t.dashboard_forms.save_error,
        description: context.t.dashboard_forms.check_form_fields_and_try_again,
      );
    }
  }

  Future<void> _pickBirthday(DateTime? currentBirthday) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentBirthday ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      ref
          .read(contactFormProvider(widget.contactId).notifier)
          .setBirthday(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(contactFormProvider(widget.contactId));

    ref.listen(contactFormProvider(widget.contactId), (prev, next) {
      final wasSaved = prev?.value?.isSaved ?? false;
      final isSaved = next.value?.isSaved ?? false;
      if (!wasSaved && isSaved) {
        Toaster.success(
          title: widget.contactId != null
              ? context.t.dashboard_forms.contact_updated
              : context.t.dashboard_forms.contact_created,
        );
        ref.read(contactFormProvider(widget.contactId).notifier).resetSaved();
        if (context.mounted) context.pop(true);
      }
    });

    return stateAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          leading: const FormCloseButton(),
          title: Text(context.t.dashboard_forms.form_error),
        ),
        body: Center(child: Text('$error')),
      ),
      data: (state) {
        if (_nameController.text != state.name) {
          _nameController.text = state.name;
        }
        if (_phoneController.text != state.phone) {
          _phoneController.text = state.phone;
        }
        if (_emailController.text != state.email) {
          _emailController.text = state.email;
        }
        if (_companyController.text != state.company) {
          _companyController.text = state.company;
        }
        if (_jobTitleController.text != state.jobTitle) {
          _jobTitleController.text = state.jobTitle;
        }
        if (_addressController.text != state.address) {
          _addressController.text = state.address;
        }
        if (_websiteController.text != state.website) {
          _websiteController.text = state.website;
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }

        return Scaffold(
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode
                  ? context.t.dashboard_forms.edit_contact
                  : context.t.dashboard_forms.new_contact,
            ),
            actions: [
              if (state.isSaving)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(icon: const Icon(Icons.save), onPressed: _save),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: formPadding,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.contact_name_label,
                    errorText: state.nameError,
                    prefixIcon: const Icon(LucideIcons.user),
                  ),
                  onChanged: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setName,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.phone_label,
                    prefixIcon: const Icon(LucideIcons.phone),
                  ),
                  onChanged: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setPhone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.email_field_label,
                    errorText: state.emailError,
                    prefixIcon: const Icon(LucideIcons.mail),
                  ),
                  onChanged: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setEmail,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _companyController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.company_label,
                    prefixIcon: const Icon(LucideIcons.building),
                  ),
                  onChanged: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setCompany,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _jobTitleController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.job_title_label,
                    prefixIcon: const Icon(LucideIcons.briefcase),
                  ),
                  onChanged: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setJobTitle,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.address_label,
                    prefixIcon: const Icon(LucideIcons.mapPin),
                  ),
                  onChanged: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _websiteController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.website_label,
                    prefixIcon: const Icon(LucideIcons.globe),
                  ),
                  onChanged: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setWebsite,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.t.dashboard_forms.birthday_label),
                  subtitle: Text(
                    state.birthday == null
                        ? context.t.dashboard_forms.not_specified
                        : '${state.birthday!.day.toString().padLeft(2, '0')}.${state.birthday!.month.toString().padLeft(2, '0')}.${state.birthday!.year}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      if (state.birthday != null)
                        IconButton(
                          tooltip: context.t.dashboard_forms.clear,
                          icon: const Icon(Icons.clear),
                          onPressed: () => ref
                              .read(
                                contactFormProvider(widget.contactId).notifier,
                              )
                              .setBirthday(null),
                        ),
                      IconButton(
                        tooltip: context.t.dashboard_forms.pick_date,
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _pickBirthday(state.birthday),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: state.isEmergencyContact,
                  onChanged: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setEmergencyContact,
                  title: Text(
                    context.t.dashboard_forms.emergency_contact_label,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                CategoryPickerField(
                  selectedCategoryId: state.categoryId,
                  selectedCategoryName: state.categoryName,
                  filterByType: const [
                    CategoryType.contact,
                    CategoryType.mixed,
                  ],
                  onCategorySelected: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setCategory,
                ),
                const SizedBox(height: 12),
                TagPickerField(
                  selectedTagIds: state.tagIds,
                  selectedTagNames: state.tagNames,
                  filterByType: const [TagType.contact, TagType.mixed],
                  onTagsSelected: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setTags,
                ),
                const SizedBox(height: 12),
                NotePickerField(
                  selectedNoteId: state.noteId,
                  selectedNoteName: state.noteName,
                  onNoteSelected: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setNote,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.description_label,
                    prefixIcon: const Icon(LucideIcons.fileText),
                  ),
                  onChanged: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setDescription,
                ),
                const SizedBox(height: 12),
                CustomFieldsEditor(
                  fields: state.customFields,
                  onChanged: ref
                      .read(contactFormProvider(widget.contactId).notifier)
                      .setCustomFields,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
