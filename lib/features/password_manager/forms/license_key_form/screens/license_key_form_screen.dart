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
import 'package:hoplixi/generated/l10n.dart';

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
  late final TextEditingController _activatedOnController;
  late final TextEditingController _purchaseDateController;
  late final TextEditingController _purchaseFromController;
  late final TextEditingController _orderIdController;
  late final TextEditingController _licenseFileIdController;
  late final TextEditingController _expiresAtController;
  late final TextEditingController _supportContactController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _productController = TextEditingController();
    _licenseKeyController = TextEditingController();
    _licenseTypeController = TextEditingController();
    _seatsController = TextEditingController();
    _maxActivationsController = TextEditingController();
    _activatedOnController = TextEditingController();
    _purchaseDateController = TextEditingController();
    _purchaseFromController = TextEditingController();
    _orderIdController = TextEditingController();
    _licenseFileIdController = TextEditingController();
    _expiresAtController = TextEditingController();
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
    _activatedOnController.dispose();
    _purchaseDateController.dispose();
    _purchaseFromController.dispose();
    _orderIdController.dispose();
    _licenseFileIdController.dispose();
    _expiresAtController.dispose();
    _supportContactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref
        .read(licenseKeyFormProvider(widget.licenseKeyId).notifier)
        .save();

    if (!mounted) return;

    if (!success) {
      Toaster.error(
        title: S.of(context).saveError,
        description: S.of(context).checkFormFieldsAndTryAgain,
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
              ? S.of(context).licenseUpdated
              : S.of(context).licenseCreated,
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
          title: Text(S.of(context).formError),
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
        if (_activatedOnController.text != state.activatedOn) {
          _activatedOnController.text = state.activatedOn;
        }
        if (_purchaseDateController.text != state.purchaseDate) {
          _purchaseDateController.text = state.purchaseDate;
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
        if (_expiresAtController.text != state.expiresAt) {
          _expiresAtController.text = state.expiresAt;
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

        return Scaffold(
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode
                  ? S.of(context).editLicense
                  : S.of(context).newLicense,
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
                  labelText: S.of(context).nameLabel,
                  errorText: state.nameError,
                ),
                onChanged: notifier.setName,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _productController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).productLabel,
                  errorText: state.productError,
                ),
                onChanged: notifier.setProduct,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _licenseKeyController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).licenseKeyLabel,
                  errorText: state.licenseKeyError,
                ),
                onChanged: notifier.setLicenseKey,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _licenseTypeController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).licenseTypeLabel,
                ),
                onChanged: notifier.setLicenseType,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _seatsController,
                keyboardType: TextInputType.number,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).seatsCountLabel,
                  errorText: state.seatsError,
                ),
                onChanged: notifier.setSeats,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxActivationsController,
                keyboardType: TextInputType.number,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).maxActivationsLabel,
                  errorText: state.maxActivationsError,
                ),
                onChanged: notifier.setMaxActivations,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _activatedOnController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).activatedAtIsoLabel,
                  errorText: state.activatedOnError,
                ),
                onChanged: notifier.setActivatedOn,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _purchaseDateController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).purchaseDateIsoLabel,
                  errorText: state.purchaseDateError,
                ),
                onChanged: notifier.setPurchaseDate,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _purchaseFromController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).purchasedFromLabel,
                ),
                onChanged: notifier.setPurchaseFrom,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _orderIdController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).orderIdLabel,
                ),
                onChanged: notifier.setOrderId,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _licenseFileIdController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).licenseFileIdLabel,
                ),
                onChanged: notifier.setLicenseFileId,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _expiresAtController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).expiresAtIsoLabel,
                  errorText: state.expiresAtError,
                ),
                onChanged: notifier.setExpiresAt,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _supportContactController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: S.of(context).supportContactLabel,
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
                  labelText: S.of(context).descriptionLabel,
                ),
                onChanged: notifier.setDescription,
              ),
            ],
          ),
        );
      },
    );
  }
}
