import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/forms/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
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
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _companyController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _websiteController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _passportNumberController;
  late final TextEditingController _driverLicenseNumberController;
  late final TextEditingController _descriptionController;

  static final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _firstNameController = TextEditingController();
    _middleNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _displayNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _companyController = TextEditingController();
    _jobTitleController = TextEditingController();
    _websiteController = TextEditingController();
    _taxIdController = TextEditingController();
    _nationalIdController = TextEditingController();
    _passportNumberController = TextEditingController();
    _driverLicenseNumberController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _websiteController.dispose();
    _taxIdController.dispose();
    _nationalIdController.dispose();
    _passportNumberController.dispose();
    _driverLicenseNumberController.dispose();
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
        if (_firstNameController.text != state.firstName) {
          _firstNameController.text = state.firstName;
        }
        if (_middleNameController.text != state.middleName) {
          _middleNameController.text = state.middleName;
        }
        if (_lastNameController.text != state.lastName) {
          _lastNameController.text = state.lastName;
        }
        if (_displayNameController.text != state.displayName) {
          _displayNameController.text = state.displayName;
        }
        if (_usernameController.text != state.username) {
          _usernameController.text = state.username;
        }
        if (_emailController.text != state.email) {
          _emailController.text = state.email;
        }
        if (_phoneController.text != state.phone) {
          _phoneController.text = state.phone;
        }
        if (_addressController.text != state.address) {
          _addressController.text = state.address;
        }
        if (_companyController.text != state.company) {
          _companyController.text = state.company;
        }
        if (_jobTitleController.text != state.jobTitle) {
          _jobTitleController.text = state.jobTitle;
        }
        if (_websiteController.text != state.website) {
          _websiteController.text = state.website;
        }
        if (_taxIdController.text != state.taxId) {
          _taxIdController.text = state.taxId;
        }
        if (_nationalIdController.text != state.nationalId) {
          _nationalIdController.text = state.nationalId;
        }
        if (_passportNumberController.text != state.passportNumber) {
          _passportNumberController.text = state.passportNumber;
        }
        if (_driverLicenseNumberController.text != state.driverLicenseNumber) {
          _driverLicenseNumberController.text = state.driverLicenseNumber;
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }

        final notifier = ref.read(
          identityFormProvider(widget.identityId).notifier,
        );

        // Отображаемые строки для полей-дейтпикеров
        final birthdayDisplay = state.birthday.isNotEmpty
            ? _dateFormat.format(
                DateTime.tryParse(state.birthday) ?? DateTime.now(),
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
                  controller: _firstNameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Имя',
                    prefixIcon: const Icon(LucideIcons.user),
                  ),
                  onChanged: notifier.setFirstName,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _middleNameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Отчество',
                    prefixIcon: const Icon(LucideIcons.user),
                  ),
                  onChanged: notifier.setMiddleName,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lastNameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Фамилия',
                    prefixIcon: const Icon(LucideIcons.user),
                  ),
                  onChanged: notifier.setLastName,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _displayNameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Отображаемое имя',
                    prefixIcon: const Icon(LucideIcons.userCheck),
                  ),
                  onChanged: notifier.setDisplayName,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _usernameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Имя пользователя',
                    prefixIcon: const Icon(LucideIcons.atSign),
                  ),
                  onChanged: notifier.setUsername,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Электронная почта',
                    prefixIcon: const Icon(LucideIcons.mail),
                  ),
                  onChanged: notifier.setEmail,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Телефон',
                    prefixIcon: const Icon(LucideIcons.phone),
                  ),
                  onChanged: notifier.setPhone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Адрес',
                    prefixIcon: const Icon(LucideIcons.mapPin),
                  ),
                  onChanged: notifier.setAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: birthdayDisplay),
                  readOnly: true,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Дата рождения',
                    errorText: state.birthdayError,
                    prefixIcon: const Icon(LucideIcons.calendar),
                    suffixIcon: state.birthday.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => notifier.setBirthday(''),
                          )
                        : null,
                  ),
                  onTap: () => _pickDate(
                    context: context,
                    current: state.birthday,
                    onChanged: notifier.setBirthday,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _companyController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Компания',
                    prefixIcon: const Icon(LucideIcons.building),
                  ),
                  onChanged: notifier.setCompany,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _jobTitleController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Должность',
                    prefixIcon: const Icon(LucideIcons.briefcase),
                  ),
                  onChanged: notifier.setJobTitle,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _websiteController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Веб-сайт',
                    prefixIcon: const Icon(LucideIcons.globe),
                  ),
                  onChanged: notifier.setWebsite,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _taxIdController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'ИНН',
                    prefixIcon: const Icon(LucideIcons.fileText),
                  ),
                  onChanged: notifier.setTaxId,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nationalIdController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'СНИЛС/Паспорт РФ',
                    prefixIcon: const Icon(LucideIcons.creditCard),
                  ),
                  onChanged: notifier.setNationalId,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passportNumberController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Загранпаспорт',
                    prefixIcon: const Icon(LucideIcons.contact),
                  ),
                  onChanged: notifier.setPassportNumber,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _driverLicenseNumberController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Водительские права',
                    prefixIcon: const Icon(LucideIcons.car),
                  ),
                  onChanged: notifier.setDriverLicenseNumber,
                ),
                const SizedBox(height: 12),
                CategoryPickerField(
                  selectedCategoryId: state.categoryId,
                  selectedCategoryName: state.categoryName,
                  onCategorySelected: notifier.setCategory,
                ),
                const SizedBox(height: 12),
                TagPickerField(
                  selectedTagIds: state.tagIds,
                  selectedTagNames: state.tagNames,
                  onTagsSelected: notifier.setTags,
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
