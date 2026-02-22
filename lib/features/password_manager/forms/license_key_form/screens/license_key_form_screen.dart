import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class LicenseKeyFormScreen extends ConsumerStatefulWidget {
  const LicenseKeyFormScreen({super.key, this.licenseKeyId});

  final String? licenseKeyId;

  bool get isEdit => licenseKeyId != null;

  @override
  ConsumerState<LicenseKeyFormScreen> createState() =>
      _LicenseKeyFormScreenState();
}

class _LicenseKeyFormScreenState extends ConsumerState<LicenseKeyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _productController = TextEditingController();
  final _licenseKeyController = TextEditingController();
  final _licenseTypeController = TextEditingController();
  final _seatsController = TextEditingController();
  final _maxActivationsController = TextEditingController();
  final _activatedOnController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  final _purchaseFromController = TextEditingController();
  final _orderIdController = TextEditingController();
  final _licenseFileIdController = TextEditingController();
  final _expiresAtController = TextEditingController();
  final _licenseNotesController = TextEditingController();
  final _supportContactController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _loading = false;

  DateTime? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  int? _parseInt(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(licenseKeyDaoProvider.future);
      final row = await dao.getById(widget.licenseKeyId!);
      if (row == null) return;
      final item = row.$1;
      final license = row.$2;

      _nameController.text = item.name;
      _productController.text = license.product;
      _licenseKeyController.text = license.licenseKey;
      _licenseTypeController.text = license.licenseType ?? '';
      _seatsController.text = license.seats?.toString() ?? '';
      _maxActivationsController.text = license.maxActivations?.toString() ?? '';
      _activatedOnController.text =
          license.activatedOn?.toIso8601String() ?? '';
      _purchaseDateController.text =
          license.purchaseDate?.toIso8601String() ?? '';
      _purchaseFromController.text = license.purchaseFrom ?? '';
      _orderIdController.text = license.orderId ?? '';
      _licenseFileIdController.text = license.licenseFileId ?? '';
      _expiresAtController.text = license.expiresAt?.toIso8601String() ?? '';
      _licenseNotesController.text = license.licenseNotes ?? '';
      _supportContactController.text = license.supportContact ?? '';
      _descriptionController.text = item.description ?? '';
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    _licenseNotesController.dispose();
    _supportContactController.dispose();
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
      final dao = await ref.read(licenseKeyDaoProvider.future);

      String? clean(TextEditingController controller) {
        final value = controller.text.trim();
        return value.isEmpty ? null : value;
      }

      final name = _nameController.text.trim();
      final product = _productController.text.trim();
      final licenseKey = _licenseKeyController.text.trim();

      if (widget.isEdit) {
        await dao.updateLicenseKey(
          widget.licenseKeyId!,
          UpdateLicenseKeyDto(
            name: name,
            product: product,
            licenseKey: licenseKey,
            licenseType: clean(_licenseTypeController),
            seats: _parseInt(_seatsController.text),
            maxActivations: _parseInt(_maxActivationsController.text),
            activatedOn: _parseDate(_activatedOnController.text),
            purchaseDate: _parseDate(_purchaseDateController.text),
            purchaseFrom: clean(_purchaseFromController),
            orderId: clean(_orderIdController),
            licenseFileId: clean(_licenseFileIdController),
            expiresAt: _parseDate(_expiresAtController.text),
            licenseNotes: clean(_licenseNotesController),
            supportContact: clean(_supportContactController),
            description: clean(_descriptionController),
          ),
        );
      } else {
        await dao.createLicenseKey(
          CreateLicenseKeyDto(
            name: name,
            product: product,
            licenseKey: licenseKey,
            licenseType: clean(_licenseTypeController),
            seats: _parseInt(_seatsController.text),
            maxActivations: _parseInt(_maxActivationsController.text),
            activatedOn: _parseDate(_activatedOnController.text),
            purchaseDate: _parseDate(_purchaseDateController.text),
            purchaseFrom: clean(_purchaseFromController),
            orderId: clean(_orderIdController),
            licenseFileId: clean(_licenseFileIdController),
            expiresAt: _parseDate(_expiresAtController.text),
            licenseNotes: clean(_licenseNotesController),
            supportContact: clean(_supportContactController),
            description: clean(_descriptionController),
          ),
        );
      }

      Toaster.success(
        title: widget.isEdit ? 'Лицензия обновлена' : 'Лицензия создана',
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
        title: Text(
          widget.isEdit ? 'Редактировать лицензию' : 'Новая лицензия',
        ),
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
                    controller: _productController,
                    decoration: const InputDecoration(labelText: 'Продукт'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Продукт обязателен'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _licenseKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Ключ лицензии',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ключ обязателен'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _licenseTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Тип лицензии',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _seatsController,
                    decoration: const InputDecoration(
                      labelText: 'Количество мест',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _maxActivationsController,
                    decoration: const InputDecoration(
                      labelText: 'Макс. активаций',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _activatedOnController,
                    decoration: const InputDecoration(
                      labelText: 'Активировано (ISO8601)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _purchaseDateController,
                    decoration: const InputDecoration(
                      labelText: 'Дата покупки (ISO8601)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _purchaseFromController,
                    decoration: const InputDecoration(labelText: 'Где куплено'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _orderIdController,
                    decoration: const InputDecoration(labelText: 'Order ID'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _licenseFileIdController,
                    decoration: const InputDecoration(
                      labelText: 'ID файла лицензии',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _expiresAtController,
                    decoration: const InputDecoration(
                      labelText: 'Истекает (ISO8601)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _licenseNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Заметки по лицензии',
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _supportContactController,
                    decoration: const InputDecoration(
                      labelText: 'Контакт поддержки',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Описание'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
    );
  }
}
