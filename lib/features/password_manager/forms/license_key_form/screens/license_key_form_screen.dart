import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/forms/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/note_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_editor.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/license_key_form_provider.dart';

class LicenseKeyFormScreen extends ConsumerStatefulWidget {
  const LicenseKeyFormScreen({super.key, this.licenseKeyId});

  final String? licenseKeyId;

  @override
  ConsumerState<LicenseKeyFormScreen> createState() =>
      _LicenseKeyFormScreenState();
}

class _LicenseKeyFormScreenState extends ConsumerState<LicenseKeyFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _productController;
  late final TextEditingController _licenseKeyController;
  late final TextEditingController _licenseTypeController;
  late final TextEditingController _seatsController;
  late final TextEditingController _maxActivationsController;
  late final TextEditingController _purchaseFromController;
  late final TextEditingController _orderIdController;
  late final TextEditingController _licenseFileIdController;
  late final TextEditingController _supportContactController;
  late final TextEditingController _descriptionController;

  static final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _productController = TextEditingController();
    _licenseKeyController = TextEditingController();
    _licenseTypeController = TextEditingController();
    _seatsController = TextEditingController();
    _maxActivationsController = TextEditingController();
    _purchaseFromController = TextEditingController();
    _orderIdController = TextEditingController();
    _licenseFileIdController = TextEditingController();
    _supportContactController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productController.dispose();
    _licenseKeyController.dispose();
    _licenseTypeController.dispose();
    _seatsController.dispose();
    _maxActivationsController.dispose();
    _purchaseFromController.dispose();
    _orderIdController.dispose();
    _licenseFileIdController.dispose();
    _supportContactController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        .read(licenseKeyFormProvider(widget.licenseKeyId).notifier)
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
    final stateAsync = ref.watch(licenseKeyFormProvider(widget.licenseKeyId));

    ref.listen(licenseKeyFormProvider(widget.licenseKeyId), (prev, next) {
      final wasSaved = prev?.value?.isSaved ?? false;
      final isSaved = next.value?.isSaved ?? false;
      if (!wasSaved && isSaved) {
        Toaster.success(
          title: widget.licenseKeyId != null
              ? context.t.dashboard_forms.license_updated
              : context.t.dashboard_forms.license_created,
        );
        ref
            .read(licenseKeyFormProvider(widget.licenseKeyId).notifier)
            .resetSaved();
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
        if (_productController.text != state.product) {
          _productController.text = state.product;
        }
        if (_licenseKeyController.text != state.licenseKey) {
          _licenseKeyController.text = state.licenseKey;
        }
        if (_licenseTypeController.text != state.licenseType) {
          _licenseTypeController.text = state.licenseType;
        }
        if (_seatsController.text != state.seats) {
          _seatsController.text = state.seats;
        }
        if (_maxActivationsController.text != state.maxActivations) {
          _maxActivationsController.text = state.maxActivations;
        }
        if (_purchaseFromController.text != state.purchaseFrom) {
          _purchaseFromController.text = state.purchaseFrom;
        }
        if (_orderIdController.text != state.orderId) {
          _orderIdController.text = state.orderId;
        }
        if (_licenseFileIdController.text != state.licenseFileId) {
          _licenseFileIdController.text = state.licenseFileId;
        }
        if (_supportContactController.text != state.supportContact) {
          _supportContactController.text = state.supportContact;
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }

        final notifier = ref.read(
          licenseKeyFormProvider(widget.licenseKeyId).notifier,
        );

        final activatedOnDisplay = state.activatedOn.isNotEmpty
            ? _dateTimeFormat.format(
                DateTime.tryParse(state.activatedOn) ?? DateTime.now(),
              )
            : '';
        final purchaseDateDisplay = state.purchaseDate.isNotEmpty
            ? _dateTimeFormat.format(
                DateTime.tryParse(state.purchaseDate) ?? DateTime.now(),
              )
            : '';
        final expiresAtDisplay = state.expiresAt.isNotEmpty
            ? _dateTimeFormat.format(
                DateTime.tryParse(state.expiresAt) ?? DateTime.now(),
              )
            : '';

        return Scaffold(
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode
                  ? context.t.dashboard_forms.edit_license
                  : context.t.dashboard_forms.new_license,
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
                  controller: _productController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.product_label,
                    errorText: state.productError,
                    prefixIcon: const Icon(LucideIcons.package),
                  ),
                  onChanged: notifier.setProduct,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _licenseKeyController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.license_key_label,
                    errorText: state.licenseKeyError,
                    prefixIcon: const Icon(LucideIcons.key),
                  ),
                  onChanged: notifier.setLicenseKey,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _licenseTypeController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.license_type_label,
                    prefixIcon: const Icon(LucideIcons.type),
                  ),
                  onChanged: notifier.setLicenseType,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _seatsController,
                  keyboardType: TextInputType.number,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.seats_count_label,
                    errorText: state.seatsError,
                    prefixIcon: const Icon(LucideIcons.users),
                  ),
                  onChanged: notifier.setSeats,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _maxActivationsController,
                  keyboardType: TextInputType.number,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.max_activations_label,
                    errorText: state.maxActivationsError,
                    prefixIcon: const Icon(LucideIcons.hash),
                  ),
                  onChanged: notifier.setMaxActivations,
                ),
                const SizedBox(height: 12),

                // Activated On
                TextField(
                  controller: TextEditingController(text: activatedOnDisplay),
                  readOnly: true,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.activated_at_iso_label,
                    errorText: state.activatedOnError,
                    prefixIcon: const Icon(LucideIcons.calendar),
                    suffixIcon: state.activatedOn.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => notifier.setActivatedOn(''),
                          )
                        : null,
                  ),
                  onTap: () => _pickDateTime(
                    context: context,
                    current: state.activatedOn,
                    onChanged: notifier.setActivatedOn,
                  ),
                ),
                const SizedBox(height: 12),

                // Purchase Date
                TextField(
                  controller: TextEditingController(text: purchaseDateDisplay),
                  readOnly: true,
                  decoration: primaryInputDecoration(
                    context,
                    labelText:
                        context.t.dashboard_forms.purchase_date_iso_label,
                    errorText: state.purchaseDateError,
                    prefixIcon: const Icon(LucideIcons.calendar),
                    suffixIcon: state.purchaseDate.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => notifier.setPurchaseDate(''),
                          )
                        : null,
                  ),
                  onTap: () => _pickDateTime(
                    context: context,
                    current: state.purchaseDate,
                    onChanged: notifier.setPurchaseDate,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _purchaseFromController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.purchased_from_label,
                    prefixIcon: const Icon(LucideIcons.shoppingCart),
                  ),
                  onChanged: notifier.setPurchaseFrom,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _orderIdController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.order_id_label,
                    prefixIcon: const Icon(LucideIcons.hash),
                  ),
                  onChanged: notifier.setOrderId,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _licenseFileIdController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.license_file_id_label,
                    prefixIcon: const Icon(LucideIcons.file),
                  ),
                  onChanged: notifier.setLicenseFileId,
                ),
                const SizedBox(height: 12),

                // Expires At
                TextField(
                  controller: TextEditingController(text: expiresAtDisplay),
                  readOnly: true,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.expires_at_iso_label,
                    errorText: state.expiresAtError,
                    prefixIcon: const Icon(LucideIcons.calendar),
                    suffixIcon: state.expiresAt.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => notifier.setExpiresAt(''),
                          )
                        : null,
                  ),
                  onTap: () => _pickDateTime(
                    context: context,
                    current: state.expiresAt,
                    onChanged: notifier.setExpiresAt,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _supportContactController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.support_contact_label,
                    prefixIcon: const Icon(LucideIcons.headphones),
                  ),
                  onChanged: notifier.setSupportContact,
                ),
                const SizedBox(height: 12),
                CategoryPickerField(
                  selectedCategoryId: state.categoryId,
                  selectedCategoryName: state.categoryName,
                  filterByType: const [
                    CategoryType.licenseKey,
                    CategoryType.mixed,
                  ],
                  onCategorySelected: notifier.setCategory,
                ),
                const SizedBox(height: 12),
                TagPickerField(
                  selectedTagIds: state.tagIds,
                  selectedTagNames: state.tagNames,
                  filterByType: const [TagType.licenseKey, TagType.mixed],
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
