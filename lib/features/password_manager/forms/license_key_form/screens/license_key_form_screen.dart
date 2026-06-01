import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/forms/form_close_button.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/license_key/license_key_items.dart'
    show LicenseType;
import 'package:hoplixi/generated/l10n/translations.g.dart';
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
  late final TextEditingController _productNameController;
  late final TextEditingController _vendorController;
  late final TextEditingController _licenseKeyController;
  late final TextEditingController _licenseTypeController;
  late final TextEditingController _licenseTypeOtherController;
  late final TextEditingController _accountEmailController;
  late final TextEditingController _accountUsernameController;
  late final TextEditingController _purchaseEmailController;
  late final TextEditingController _orderNumberController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _seatsController;
  late final TextEditingController _activationLimitController;
  late final TextEditingController _activationsUsedController;
  late final TextEditingController _descriptionController;

  static final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _productNameController = TextEditingController();
    _vendorController = TextEditingController();
    _licenseKeyController = TextEditingController();
    _licenseTypeController = TextEditingController();
    _licenseTypeOtherController = TextEditingController();
    _accountEmailController = TextEditingController();
    _accountUsernameController = TextEditingController();
    _purchaseEmailController = TextEditingController();
    _orderNumberController = TextEditingController();
    _purchasePriceController = TextEditingController();
    _currencyController = TextEditingController();
    _seatsController = TextEditingController();
    _activationLimitController = TextEditingController();
    _activationsUsedController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productNameController.dispose();
    _vendorController.dispose();
    _licenseKeyController.dispose();
    _licenseTypeController.dispose();
    _licenseTypeOtherController.dispose();
    _accountEmailController.dispose();
    _accountUsernameController.dispose();
    _purchaseEmailController.dispose();
    _orderNumberController.dispose();
    _purchasePriceController.dispose();
    _currencyController.dispose();
    _seatsController.dispose();
    _activationLimitController.dispose();
    _activationsUsedController.dispose();
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
        if (_productNameController.text != state.productName) {
          _productNameController.text = state.productName;
        }
        if (_vendorController.text != state.vendor) {
          _vendorController.text = state.vendor;
        }
        if (_licenseKeyController.text != state.licenseKey) {
          _licenseKeyController.text = state.licenseKey;
        }
        if (_licenseTypeController.text != (state.licenseType ?? '')) {
          _licenseTypeController.text = state.licenseType ?? '';
        }
        if (_licenseTypeOtherController.text != state.licenseTypeOther) {
          _licenseTypeOtherController.text = state.licenseTypeOther;
        }
        if (_accountEmailController.text != state.accountEmail) {
          _accountEmailController.text = state.accountEmail;
        }
        if (_accountUsernameController.text != state.accountUsername) {
          _accountUsernameController.text = state.accountUsername;
        }
        if (_purchaseEmailController.text != state.purchaseEmail) {
          _purchaseEmailController.text = state.purchaseEmail;
        }
        if (_orderNumberController.text != state.orderNumber) {
          _orderNumberController.text = state.orderNumber;
        }
        if (_purchasePriceController.text != state.purchasePrice) {
          _purchasePriceController.text = state.purchasePrice;
        }
        if (_currencyController.text != state.currency) {
          _currencyController.text = state.currency;
        }
        if (_seatsController.text != state.seats) {
          _seatsController.text = state.seats;
        }
        if (_activationLimitController.text != state.activationLimit) {
          _activationLimitController.text = state.activationLimit;
        }
        if (_activationsUsedController.text != state.activationsUsed) {
          _activationsUsedController.text = state.activationsUsed;
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }

        final notifier = ref.read(
          licenseKeyFormProvider(widget.licenseKeyId).notifier,
        );

        final validFromDisplay = state.validFrom.isNotEmpty
            ? _dateTimeFormat.format(
                DateTime.tryParse(state.validFrom) ?? DateTime.now(),
              )
            : '';
        final purchaseDateDisplay = state.purchaseDate.isNotEmpty
            ? _dateTimeFormat.format(
                DateTime.tryParse(state.purchaseDate) ?? DateTime.now(),
              )
            : '';
        final validToDisplay = state.validTo.isNotEmpty
            ? _dateTimeFormat.format(
                DateTime.tryParse(state.validTo) ?? DateTime.now(),
              )
            : '';
        final renewalDateDisplay = state.renewalDate.isNotEmpty
            ? _dateTimeFormat.format(
                DateTime.tryParse(state.renewalDate) ?? DateTime.now(),
              )
            : '';

        return Scaffold(
          backgroundColor: getScreenBackgroundColor(context, ref),
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
                  controller: _productNameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.product_label,
                    errorText: state.productNameError,
                    prefixIcon: const Icon(LucideIcons.package),
                  ),
                  onChanged: notifier.setProductName,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _vendorController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Продавец',
                    prefixIcon: const Icon(LucideIcons.shoppingCart),
                  ),
                  onChanged: notifier.setVendor,
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
                DropdownButtonFormField<String>(
                  initialValue: state.licenseType,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: context.t.dashboard_forms.license_type_label,
                    prefixIcon: const Icon(LucideIcons.type),
                  ),
                  items: LicenseType.values.map((type) {
                    return DropdownMenuItem<String>(
                      value: type.name,
                      child: Text(type.name),
                    );
                  }).toList(),
                  onChanged: notifier.setLicenseType,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _licenseTypeOtherController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Другой тип лицензии',
                    prefixIcon: const Icon(LucideIcons.type),
                  ),
                  onChanged: notifier.setLicenseTypeOther,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accountEmailController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Email аккаунта',
                    prefixIcon: const Icon(LucideIcons.mail),
                  ),
                  onChanged: notifier.setAccountEmail,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accountUsernameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Логин аккаунта',
                    prefixIcon: const Icon(LucideIcons.user),
                  ),
                  onChanged: notifier.setAccountUsername,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _purchaseEmailController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Email покупки',
                    prefixIcon: const Icon(LucideIcons.mail),
                  ),
                  onChanged: notifier.setPurchaseEmail,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _orderNumberController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Номер заказа',
                    prefixIcon: const Icon(LucideIcons.hash),
                  ),
                  onChanged: notifier.setOrderNumber,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _purchasePriceController,
                  keyboardType: TextInputType.number,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Цена покупки',
                    prefixIcon: const Icon(LucideIcons.dollarSign),
                  ),
                  onChanged: notifier.setPurchasePrice,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _currencyController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Валюта',
                    prefixIcon: const Icon(LucideIcons.coins),
                  ),
                  onChanged: notifier.setCurrency,
                ),
                const SizedBox(height: 12),

                // Valid From
                TextField(
                  controller: TextEditingController(text: validFromDisplay),
                  readOnly: true,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Действителен с',
                    errorText: state.validFromError,
                    prefixIcon: const Icon(LucideIcons.calendar),
                    suffixIcon: state.validFrom.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => notifier.setValidFrom(''),
                          )
                        : null,
                  ),
                  onTap: () => _pickDateTime(
                    context: context,
                    current: state.validFrom,
                    onChanged: notifier.setValidFrom,
                  ),
                ),
                const SizedBox(height: 12),

                // Valid To
                TextField(
                  controller: TextEditingController(text: validToDisplay),
                  readOnly: true,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Действителен до',
                    errorText: state.validToError,
                    prefixIcon: const Icon(LucideIcons.calendar),
                    suffixIcon: state.validTo.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => notifier.setValidTo(''),
                          )
                        : null,
                  ),
                  onTap: () => _pickDateTime(
                    context: context,
                    current: state.validTo,
                    onChanged: notifier.setValidTo,
                  ),
                ),
                const SizedBox(height: 12),

                // Renewal Date
                TextField(
                  controller: TextEditingController(text: renewalDateDisplay),
                  readOnly: true,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Дата продления',
                    errorText: state.renewalDateError,
                    prefixIcon: const Icon(LucideIcons.calendar),
                    suffixIcon: state.renewalDate.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => notifier.setRenewalDate(''),
                          )
                        : null,
                  ),
                  onTap: () => _pickDateTime(
                    context: context,
                    current: state.renewalDate,
                    onChanged: notifier.setRenewalDate,
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
                  controller: _activationLimitController,
                  keyboardType: TextInputType.number,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Лимит активаций',
                    errorText: state.activationLimitError,
                    prefixIcon: const Icon(LucideIcons.hash),
                  ),
                  onChanged: notifier.setActivationLimit,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _activationsUsedController,
                  keyboardType: TextInputType.number,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Использовано активаций',
                    errorText: state.activationsUsedError,
                    prefixIcon: const Icon(LucideIcons.hash),
                  ),
                  onChanged: notifier.setActivationsUsed,
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
