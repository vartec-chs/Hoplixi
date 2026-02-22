import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

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
  late final TextEditingController _notesController;
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
    _notesController = TextEditingController();
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
    _notesController.dispose();
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
        title: 'Ошибка сохранения',
        description: 'Проверьте поля формы и попробуйте снова',
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
              ? 'Контакт обновлен'
              : 'Контакт создан',
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
          title: const Text('Ошибка формы'),
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
        if (_notesController.text != state.notes) {
          _notesController.text = state.notes;
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }

        return Scaffold(
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode ? 'Редактировать контакт' : 'Новый контакт',
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
          body: ListView(
            padding: formPadding,
            children: [
              TextField(
                controller: _nameController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Имя контакта *',
                  errorText: state.nameError,
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
                  labelText: 'Телефон',
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
                  labelText: 'Email',
                  errorText: state.emailError,
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
                  labelText: 'Компания',
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
                  labelText: 'Должность',
                ),
                onChanged: ref
                    .read(contactFormProvider(widget.contactId).notifier)
                    .setJobTitle,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: primaryInputDecoration(context, labelText: 'Адрес'),
                onChanged: ref
                    .read(contactFormProvider(widget.contactId).notifier)
                    .setAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _websiteController,
                decoration: primaryInputDecoration(context, labelText: 'Сайт'),
                onChanged: ref
                    .read(contactFormProvider(widget.contactId).notifier)
                    .setWebsite,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Дата рождения'),
                subtitle: Text(
                  state.birthday == null
                      ? 'Не указана'
                      : '${state.birthday!.day.toString().padLeft(2, '0')}.${state.birthday!.month.toString().padLeft(2, '0')}.${state.birthday!.year}',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    if (state.birthday != null)
                      IconButton(
                        tooltip: 'Очистить',
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref
                            .read(
                              contactFormProvider(widget.contactId).notifier,
                            )
                            .setBirthday(null),
                      ),
                    IconButton(
                      tooltip: 'Выбрать дату',
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
                title: const Text('Экстренный контакт'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              CategoryPickerField(
                selectedCategoryId: state.categoryId,
                selectedCategoryName: state.categoryName,
                filterByType: const [CategoryType.contact, CategoryType.mixed],
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
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Заметки',
                ),
                onChanged: ref
                    .read(contactFormProvider(widget.contactId).notifier)
                    .setNotes,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Описание',
                ),
                onChanged: ref
                    .read(contactFormProvider(widget.contactId).notifier)
                    .setDescription,
              ),
            ],
          ),
        );
      },
    );
  }
}
