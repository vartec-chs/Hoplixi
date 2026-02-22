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

import '../providers/identity_form_provider.dart';

class IdentityFormScreen extends ConsumerStatefulWidget {
  const IdentityFormScreen({super.key, this.identityId});

  final String? identityId;

  @override
  ConsumerState<IdentityFormScreen> createState() => _IdentityFormScreenState();
}

class _IdentityFormScreenState extends ConsumerState<IdentityFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _idTypeController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _dateOfBirthController;
  late final TextEditingController _placeOfBirthController;
  late final TextEditingController _nationalityController;
  late final TextEditingController _issuingAuthorityController;
  late final TextEditingController _issueDateController;
  late final TextEditingController _expiryDateController;
  late final TextEditingController _mrzController;
  late final TextEditingController _scanAttachmentIdController;
  late final TextEditingController _photoAttachmentIdController;
  late final TextEditingController _notesController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _idTypeController = TextEditingController();
    _idNumberController = TextEditingController();
    _fullNameController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _placeOfBirthController = TextEditingController();
    _nationalityController = TextEditingController();
    _issuingAuthorityController = TextEditingController();
    _issueDateController = TextEditingController();
    _expiryDateController = TextEditingController();
    _mrzController = TextEditingController();
    _scanAttachmentIdController = TextEditingController();
    _photoAttachmentIdController = TextEditingController();
    _notesController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idTypeController.dispose();
    _idNumberController.dispose();
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _placeOfBirthController.dispose();
    _nationalityController.dispose();
    _issuingAuthorityController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _mrzController.dispose();
    _scanAttachmentIdController.dispose();
    _photoAttachmentIdController.dispose();
    _notesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref
        .read(identityFormProvider(widget.identityId).notifier)
        .save();

    if (!mounted) return;

    if (!success) {
      Toaster.error(
        title: 'Ошибка сохранения',
        description: 'Проверьте поля формы и попробуйте снова',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(identityFormProvider(widget.identityId));

    ref.listen(identityFormProvider(widget.identityId), (prev, next) {
      final wasSaved = prev?.value?.isSaved ?? false;
      final isSaved = next.value?.isSaved ?? false;
      if (!wasSaved && isSaved) {
        Toaster.success(
          title: widget.identityId != null
              ? 'Идентификация обновлена'
              : 'Идентификация создана',
        );
        ref.read(identityFormProvider(widget.identityId).notifier).resetSaved();
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
        if (_nameController.text != state.name)
          _nameController.text = state.name;
        if (_idTypeController.text != state.idType)
          _idTypeController.text = state.idType;
        if (_idNumberController.text != state.idNumber)
          _idNumberController.text = state.idNumber;
        if (_fullNameController.text != state.fullName)
          _fullNameController.text = state.fullName;
        if (_dateOfBirthController.text != state.dateOfBirth)
          _dateOfBirthController.text = state.dateOfBirth;
        if (_placeOfBirthController.text != state.placeOfBirth)
          _placeOfBirthController.text = state.placeOfBirth;
        if (_nationalityController.text != state.nationality)
          _nationalityController.text = state.nationality;
        if (_issuingAuthorityController.text != state.issuingAuthority)
          _issuingAuthorityController.text = state.issuingAuthority;
        if (_issueDateController.text != state.issueDate)
          _issueDateController.text = state.issueDate;
        if (_expiryDateController.text != state.expiryDate)
          _expiryDateController.text = state.expiryDate;
        if (_mrzController.text != state.mrz) _mrzController.text = state.mrz;
        if (_scanAttachmentIdController.text != state.scanAttachmentId)
          _scanAttachmentIdController.text = state.scanAttachmentId;
        if (_photoAttachmentIdController.text != state.photoAttachmentId)
          _photoAttachmentIdController.text = state.photoAttachmentId;
        if (_notesController.text != state.notes)
          _notesController.text = state.notes;
        if (_descriptionController.text != state.description)
          _descriptionController.text = state.description;

        final notifier = ref.read(
          identityFormProvider(widget.identityId).notifier,
        );

        return Scaffold(
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode ? 'Редактировать ID' : 'Новая идентификация',
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
                  labelText: 'Название *',
                  errorText: state.nameError,
                ),
                onChanged: notifier.setName,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _idTypeController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Тип документа *',
                  errorText: state.idTypeError,
                ),
                onChanged: notifier.setIdType,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _idNumberController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Номер документа *',
                  errorText: state.idNumberError,
                ),
                onChanged: notifier.setIdNumber,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fullNameController,
                decoration: primaryInputDecoration(context, labelText: 'ФИО'),
                onChanged: notifier.setFullName,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dateOfBirthController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Дата рождения (ISO8601)',
                  errorText: state.dateOfBirthError,
                ),
                onChanged: notifier.setDateOfBirth,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _placeOfBirthController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Место рождения',
                ),
                onChanged: notifier.setPlaceOfBirth,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nationalityController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Гражданство',
                ),
                onChanged: notifier.setNationality,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _issuingAuthorityController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Кем выдан',
                ),
                onChanged: notifier.setIssuingAuthority,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _issueDateController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Дата выдачи (ISO8601)',
                  errorText: state.issueDateError,
                ),
                onChanged: notifier.setIssueDate,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _expiryDateController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Дата окончания (ISO8601)',
                  errorText: state.expiryDateError,
                ),
                onChanged: notifier.setExpiryDate,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mrzController,
                minLines: 2,
                maxLines: 4,
                decoration: primaryInputDecoration(context, labelText: 'MRZ'),
                onChanged: notifier.setMrz,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _scanAttachmentIdController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'ID скана',
                ),
                onChanged: notifier.setScanAttachmentId,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _photoAttachmentIdController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'ID фото',
                ),
                onChanged: notifier.setPhotoAttachmentId,
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
                onChanged: notifier.setNotes,
              ),
              const SizedBox(height: 12),
              CategoryPickerField(
                selectedCategoryId: state.categoryId,
                selectedCategoryName: state.categoryName,
                filterByType: const [CategoryType.identity, CategoryType.mixed],
                onCategorySelected: notifier.setCategory,
              ),
              const SizedBox(height: 12),
              TagPickerField(
                selectedTagIds: state.tagIds,
                selectedTagNames: state.tagNames,
                filterByType: const [TagType.identity, TagType.mixed],
                onTagsSelected: notifier.setTags,
              ),
              const SizedBox(height: 12),
              NotePickerField(
                selectedNoteId: state.noteId,
                selectedNoteName: state.noteName,
                onNoteSelected: notifier.setNote,
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
                onChanged: notifier.setDescription,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: state.verified,
                onChanged: notifier.setVerified,
                title: const Text('Верифицировано'),
              ),
            ],
          ),
        );
      },
    );
  }
}
