import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/forms/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/document_picker/document_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/file_picker/file_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_editor.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  late final TextEditingController _placeOfBirthController;
  late final TextEditingController _nationalityController;
  late final TextEditingController _issuingAuthorityController;
  late final TextEditingController _mrzController;
  late final TextEditingController _descriptionController;

  static final _dateFormat = DateFormat('dd.MM.yyyy');
  static final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _idTypeController = TextEditingController();
    _idNumberController = TextEditingController();
    _fullNameController = TextEditingController();
    _placeOfBirthController = TextEditingController();
    _nationalityController = TextEditingController();
    _issuingAuthorityController = TextEditingController();
    _mrzController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idTypeController.dispose();
    _idNumberController.dispose();
    _fullNameController.dispose();
    _placeOfBirthController.dispose();
    _nationalityController.dispose();
    _issuingAuthorityController.dispose();
    _mrzController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Открывает выбор только даты и передаёт результат в [onChanged] в ISO 8601.
  Future<void> _pickDate({
    required BuildContext context,
    required String current,
    required void Function(String) onChanged,
  }) async {
    final initial = DateTime.tryParse(current) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 150),
    );
    if (date != null) {
      onChanged(date.toIso8601String());
    }
  }

  /// Открывает выбор даты + времени и передаёт результат в [onChanged] в ISO 8601.
  Future<void> _pickDateTime({
    required BuildContext context,
    required String current,
    required void Function(String) onChanged,
  }) async {
    final initial = DateTime.tryParse(current) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 150),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time != null) {
      final result = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      onChanged(result.toIso8601String());
    }
  }

  Future<void> _save() async {
    final success = await ref
        .read(identityFormProvider(widget.identityId).notifier)
        .save();

    if (!mounted) return;

    if (!success) {
      Toaster.error(
        title: context.t.dashboard_forms.save_error,
        description: context.t.dashboard_forms.check_form_fields_and_try_again,
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
              ? context.t.dashboard_forms.identity_updated
              : context.t.dashboard_forms.identity_created,
        );
        ref.read(identityFormProvider(widget.identityId).notifier).resetSaved();
        if (context.mounted) context.pop(true);
      }
    });

    return stateAsync.when(
      loading: () => Scaffold(
        backgroundColor: getScreenBackgroundColor(context, ref),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: getScreenBackgroundColor(context, ref),
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
        if (_idTypeController.text != state.idType) {
          _idTypeController.text = state.idType;
        }
        if (_idNumberController.text != state.idNumber) {
          _idNumberController.text = state.idNumber;
        }
        if (_fullNameController.text != state.fullName) {
          _fullNameController.text = state.fullName;
        }
        if (_placeOfBirthController.text != state.placeOfBirth) {
          _placeOfBirthController.text = state.placeOfBirth;
        }
        if (_nationalityController.text != state.nationality) {
          _nationalityController.text = state.nationality;
        }
        if (_issuingAuthorityController.text != state.issuingAuthority) {
          _issuingAuthorityController.text = state.issuingAuthority;
        }
        if (_mrzController.text != state.mrz) _mrzController.text = state.mrz;
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }

        final notifier = ref.read(
          identityFormProvider(widget.identityId).notifier,
        );

        // Отображаемые строки для полей-дейтпикеров
        final dateOfBirthDisplay = state.dateOfBirth.isNotEmpty
            ? _dateFormat.format(
                DateTime.tryParse(state.dateOfBirth) ?? DateTime.now(),
              )
            : '';
        final issueDateDisplay = state.issueDate.isNotEmpty
            ? _dateTimeFormat.format(
                DateTime.tryParse(state.issueDate) ?? DateTime.now(),
              )
            : '';
        final expiryDateDisplay = state.expiryDate.isNotEmpty
            ? _dateTimeFormat.format(
                DateTime.tryParse(state.expiryDate) ?? DateTime.now(),
              )
            : '';

        return Scaffold(
          backgroundColor: getScreenBackgroundColor(context, ref),
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode
                  ? context.t.dashboard_forms.edit_identity
                  : context.t.dashboard_forms.new_identity,
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
                    labelText: context.t.dashboard_forms.name_label,
                    errorText: state.nameError,
                    prefixIcon: const Icon(LucideIcons.tag),
                  ),
                  onChanged: notifier.setName,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _idTypeController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText:
                        context.t.dashboard_forms.document_type_required_label,
                    errorText: state.idTypeError,
                    prefixIcon: const Icon(LucideIcons.idCard),
                  ),
                  onChanged: notifier.setIdType,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _idNumberController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context
                        .t
                        .dashboard_forms
                        .document_number_required_label,
                    errorText: state.idNumberError,
                    prefixIcon: const Icon(LucideIcons.hash),
                  ),
                  onChanged: notifier.setIdNumber,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fullNameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.full_name_label,
                    prefixIcon: const Icon(LucideIcons.user),
                  ),
                  onChanged: notifier.setFullName,
                ),
                const SizedBox(height: 12),

                // Дата рождения — только дата
                TextField(
                  controller: TextEditingController(text: dateOfBirthDisplay),
                  readOnly: true,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.birth_date_iso_label,
                    errorText: state.dateOfBirthError,
                    prefixIcon: const Icon(LucideIcons.calendar),
                    suffixIcon: state.dateOfBirth.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => notifier.setDateOfBirth(''),
                          )
                        : null,
                  ),
                  onTap: () => _pickDate(
                    context: context,
                    current: state.dateOfBirth,
                    onChanged: notifier.setDateOfBirth,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _placeOfBirthController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.place_of_birth_label,
                    prefixIcon: const Icon(LucideIcons.mapPin),
                  ),
                  onChanged: notifier.setPlaceOfBirth,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nationalityController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.nationality_label,
                    prefixIcon: const Icon(LucideIcons.flag),
                  ),
                  onChanged: notifier.setNationality,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _issuingAuthorityController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText:
                        context.t.dashboard_forms.issuing_authority_label,
                    prefixIcon: const Icon(LucideIcons.building),
                  ),
                  onChanged: notifier.setIssuingAuthority,
                ),
                const SizedBox(height: 12),

                // Дата выдачи — дата + время
                TextField(
                  controller: TextEditingController(text: issueDateDisplay),
                  readOnly: true,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.issue_date_iso_label,
                    errorText: state.issueDateError,
                    prefixIcon: const Icon(LucideIcons.calendar),
                    suffixIcon: state.issueDate.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => notifier.setIssueDate(''),
                          )
                        : null,
                  ),
                  onTap: () => _pickDateTime(
                    context: context,
                    current: state.issueDate,
                    onChanged: notifier.setIssueDate,
                  ),
                ),
                const SizedBox(height: 12),

                // Дата истечения — дата + время
                TextField(
                  controller: TextEditingController(text: expiryDateDisplay),
                  readOnly: true,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.expiry_date_iso_label,
                    errorText: state.expiryDateError,
                    prefixIcon: const Icon(LucideIcons.calendarX),
                    suffixIcon: state.expiryDate.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => notifier.setExpiryDate(''),
                          )
                        : null,
                  ),
                  onTap: () => _pickDateTime(
                    context: context,
                    current: state.expiryDate,
                    onChanged: notifier.setExpiryDate,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _mrzController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.mrz_label,
                    prefixIcon: const Icon(LucideIcons.code),
                  ),
                  onChanged: notifier.setMrz,
                ),
                const SizedBox(height: 12),

                // Скан документа → DocumentPickerField
                DocumentPickerField(
                  selectedDocumentId: state.scanAttachmentId,
                  selectedDocumentTitle: state.scanAttachmentName,
                  label: context.t.dashboard_forms.scan_id_label,
                  onDocumentSelected: notifier.setScanAttachment,
                ),
                const SizedBox(height: 12),

                // Фото → FilePickerField
                FilePickerField(
                  selectedFileId: state.photoAttachmentId,
                  selectedFileName: state.photoAttachmentName,
                  label: context.t.dashboard_forms.photo_id_label,
                  onFileSelected: notifier.setPhotoAttachment,
                ),
                const SizedBox(height: 12),

                CategoryPickerField(
                  selectedCategoryId: state.categoryId,
                  selectedCategoryName: state.categoryName,
                  filterByType: const [
                    CategoryType.identity,
                    CategoryType.mixed,
                  ],
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
                    labelText: context.t.dashboard_forms.description_label,
                    prefixIcon: const Icon(LucideIcons.fileText),
                  ),
                  onChanged: notifier.setDescription,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: state.verified,
                  onChanged: notifier.setVerified,
                  title: Text(context.t.dashboard_forms.verified_label),
                ),
                const SizedBox(height: 12),
                CustomFieldsEditor(
                  fields: state.customFields,
                  onChanged: notifier.setCustomFields,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
