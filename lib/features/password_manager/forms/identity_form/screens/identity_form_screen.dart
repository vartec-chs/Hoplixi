import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class IdentityFormScreen extends ConsumerStatefulWidget {
  const IdentityFormScreen({super.key, this.identityId});

  final String? identityId;

  bool get isEdit => identityId != null;

  @override
  ConsumerState<IdentityFormScreen> createState() => _IdentityFormScreenState();
}

class _IdentityFormScreenState extends ConsumerState<IdentityFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _idTypeController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _issuingAuthorityController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _mrzController = TextEditingController();
  final _scanAttachmentIdController = TextEditingController();
  final _photoAttachmentIdController = TextEditingController();
  final _notesController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _verified = false;
  bool _loading = false;

  DateTime? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(identityDaoProvider.future);
      final row = await dao.getById(widget.identityId!);
      if (row == null) return;
      final item = row.$1;
      final identity = row.$2;

      _nameController.text = item.name;
      _idTypeController.text = identity.idType;
      _idNumberController.text = identity.idNumber;
      _fullNameController.text = identity.fullName ?? '';
      _dateOfBirthController.text =
          identity.dateOfBirth?.toIso8601String() ?? '';
      _placeOfBirthController.text = identity.placeOfBirth ?? '';
      _nationalityController.text = identity.nationality ?? '';
      _issuingAuthorityController.text = identity.issuingAuthority ?? '';
      _issueDateController.text = identity.issueDate?.toIso8601String() ?? '';
      _expiryDateController.text = identity.expiryDate?.toIso8601String() ?? '';
      _mrzController.text = identity.mrz ?? '';
      _scanAttachmentIdController.text = identity.scanAttachmentId ?? '';
      _photoAttachmentIdController.text = identity.photoAttachmentId ?? '';
      _notesController.text = identity.notes ?? '';
      _descriptionController.text = item.description ?? '';
      _verified = identity.verified;
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      Toaster.error(title: 'Проверьте поля формы');
      return;
    }

    setState(() => _loading = true);
    try {
      final dao = await ref.read(identityDaoProvider.future);

      String? clean(TextEditingController controller) {
        final value = controller.text.trim();
        return value.isEmpty ? null : value;
      }

      final name = _nameController.text.trim();
      final idType = _idTypeController.text.trim();
      final idNumber = _idNumberController.text.trim();

      if (widget.isEdit) {
        await dao.updateIdentity(
          widget.identityId!,
          UpdateIdentityDto(
            name: name,
            idType: idType,
            idNumber: idNumber,
            fullName: clean(_fullNameController),
            dateOfBirth: _parseDate(_dateOfBirthController.text),
            placeOfBirth: clean(_placeOfBirthController),
            nationality: clean(_nationalityController),
            issuingAuthority: clean(_issuingAuthorityController),
            issueDate: _parseDate(_issueDateController.text),
            expiryDate: _parseDate(_expiryDateController.text),
            mrz: clean(_mrzController),
            scanAttachmentId: clean(_scanAttachmentIdController),
            photoAttachmentId: clean(_photoAttachmentIdController),
            notes: clean(_notesController),
            verified: _verified,
            description: clean(_descriptionController),
          ),
        );
      } else {
        await dao.createIdentity(
          CreateIdentityDto(
            name: name,
            idType: idType,
            idNumber: idNumber,
            fullName: clean(_fullNameController),
            dateOfBirth: _parseDate(_dateOfBirthController.text),
            placeOfBirth: clean(_placeOfBirthController),
            nationality: clean(_nationalityController),
            issuingAuthority: clean(_issuingAuthorityController),
            issueDate: _parseDate(_issueDateController.text),
            expiryDate: _parseDate(_expiryDateController.text),
            mrz: clean(_mrzController),
            scanAttachmentId: clean(_scanAttachmentIdController),
            photoAttachmentId: clean(_photoAttachmentIdController),
            notes: clean(_notesController),
            verified: _verified,
            description: clean(_descriptionController),
          ),
        );
      }

      Toaster.success(
        title: widget.isEdit
            ? 'Идентификация обновлена'
            : 'Идентификация создана',
      );
      if (mounted) context.pop();
    } catch (e) {
      Toaster.error(title: 'Ошибка сохранения', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Редактировать ID' : 'Новая идентификация'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Название'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Название обязательно'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _idTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Тип документа',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Тип обязателен'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _idNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Номер документа',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Номер обязателен'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'ФИО'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dateOfBirthController,
                    decoration: const InputDecoration(
                      labelText: 'Дата рождения (ISO8601)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _placeOfBirthController,
                    decoration: const InputDecoration(
                      labelText: 'Место рождения',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nationalityController,
                    decoration: const InputDecoration(labelText: 'Гражданство'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _issuingAuthorityController,
                    decoration: const InputDecoration(labelText: 'Кем выдан'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _issueDateController,
                    decoration: const InputDecoration(
                      labelText: 'Дата выдачи (ISO8601)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _expiryDateController,
                    decoration: const InputDecoration(
                      labelText: 'Дата окончания (ISO8601)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mrzController,
                    decoration: const InputDecoration(labelText: 'MRZ'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _scanAttachmentIdController,
                    decoration: const InputDecoration(labelText: 'ID скана'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _photoAttachmentIdController,
                    decoration: const InputDecoration(labelText: 'ID фото'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Заметки'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Описание'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  SwitchListTile(
                    value: _verified,
                    onChanged: (v) => setState(() => _verified = v),
                    title: const Text('Верифицировано'),
                  ),
                ],
              ),
            ),
    );
  }
}
