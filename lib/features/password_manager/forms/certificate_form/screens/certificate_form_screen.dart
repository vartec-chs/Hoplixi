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

import '../providers/certificate_form_provider.dart';

class CertificateFormScreen extends ConsumerStatefulWidget {
  const CertificateFormScreen({super.key, this.certificateId});

  final String? certificateId;

  @override
  ConsumerState<CertificateFormScreen> createState() =>
      _CertificateFormScreenState();
}

class _CertificateFormScreenState extends ConsumerState<CertificateFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _certificatePemController;
  late final TextEditingController _privateKeyController;
  late final TextEditingController _serialController;
  late final TextEditingController _issuerController;
  late final TextEditingController _subjectController;
  late final TextEditingController _fingerprintController;
  late final TextEditingController _ocspController;
  late final TextEditingController _crlController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _certificatePemController = TextEditingController();
    _privateKeyController = TextEditingController();
    _serialController = TextEditingController();
    _issuerController = TextEditingController();
    _subjectController = TextEditingController();
    _fingerprintController = TextEditingController();
    _ocspController = TextEditingController();
    _crlController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _certificatePemController.dispose();
    _privateKeyController.dispose();
    _serialController.dispose();
    _issuerController.dispose();
    _subjectController.dispose();
    _fingerprintController.dispose();
    _ocspController.dispose();
    _crlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref
        .read(certificateFormProvider(widget.certificateId).notifier)
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
    final stateAsync = ref.watch(certificateFormProvider(widget.certificateId));

    ref.listen(certificateFormProvider(widget.certificateId), (prev, next) {
      final wasSaved = prev?.value?.isSaved ?? false;
      final isSaved = next.value?.isSaved ?? false;
      if (!wasSaved && isSaved) {
        Toaster.success(
          title: widget.certificateId != null
              ? 'Сертификат обновлен'
              : 'Сертификат создан',
        );
        ref
            .read(certificateFormProvider(widget.certificateId).notifier)
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
          title: const Text('Ошибка формы'),
        ),
        body: Center(child: Text('$error')),
      ),
      data: (state) {
        if (_nameController.text != state.name) {
          _nameController.text = state.name;
        }
        if (_certificatePemController.text != state.certificatePem) {
          _certificatePemController.text = state.certificatePem;
        }
        if (_privateKeyController.text != state.privateKey) {
          _privateKeyController.text = state.privateKey;
        }
        if (_serialController.text != state.serialNumber) {
          _serialController.text = state.serialNumber;
        }
        if (_issuerController.text != state.issuer) {
          _issuerController.text = state.issuer;
        }
        if (_subjectController.text != state.subject) {
          _subjectController.text = state.subject;
        }
        if (_fingerprintController.text != state.fingerprint) {
          _fingerprintController.text = state.fingerprint;
        }
        if (_ocspController.text != state.ocspUrl) {
          _ocspController.text = state.ocspUrl;
        }
        if (_crlController.text != state.crlUrl) {
          _crlController.text = state.crlUrl;
        }
        if (_descriptionController.text != state.description) {
          _descriptionController.text = state.description;
        }

        final notifier = ref.read(
          certificateFormProvider(widget.certificateId).notifier,
        );

        return Scaffold(
          appBar: AppBar(
            leading: const FormCloseButton(),
            title: Text(
              state.isEditMode
                  ? 'Редактировать сертификат'
                  : 'Новый сертификат',
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
                controller: _certificatePemController,
                minLines: 3,
                maxLines: 8,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Certificate PEM *',
                  errorText: state.certificatePemError,
                ),
                onChanged: notifier.setCertificatePem,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _privateKeyController,
                minLines: 2,
                maxLines: 6,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Private key',
                ),
                onChanged: notifier.setPrivateKey,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _serialController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Serial number',
                ),
                onChanged: notifier.setSerialNumber,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _issuerController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Issuer',
                ),
                onChanged: notifier.setIssuer,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Subject',
                ),
                onChanged: notifier.setSubject,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fingerprintController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Fingerprint',
                ),
                onChanged: notifier.setFingerprint,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ocspController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'OCSP URL',
                ),
                onChanged: notifier.setOcspUrl,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _crlController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'CRL URL',
                ),
                onChanged: notifier.setCrlUrl,
              ),
              const SizedBox(height: 12),
              CategoryPickerField(
                selectedCategoryId: state.categoryId,
                selectedCategoryName: state.categoryName,
                filterByType: const [
                  CategoryType.certificate,
                  CategoryType.mixed,
                ],
                onCategorySelected: notifier.setCategory,
              ),
              const SizedBox(height: 12),
              TagPickerField(
                selectedTagIds: state.tagIds,
                selectedTagNames: state.tagNames,
                filterByType: const [TagType.certificate, TagType.mixed],
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
                value: state.autoRenew,
                onChanged: notifier.setAutoRenew,
                title: const Text('Auto-renew'),
              ),
            ],
          ),
        );
      },
    );
  }
}
