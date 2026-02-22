import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class RecoveryCodesFormScreen extends ConsumerStatefulWidget {
  const RecoveryCodesFormScreen({super.key, this.recoveryCodesId});

  final String? recoveryCodesId;

  bool get isEdit => recoveryCodesId != null;

  @override
  ConsumerState<RecoveryCodesFormScreen> createState() =>
      _RecoveryCodesFormScreenState();
}

class _RecoveryCodesFormScreenState
    extends ConsumerState<RecoveryCodesFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codesBlobController = TextEditingController();
  final _codesCountController = TextEditingController();
  final _usedCountController = TextEditingController();
  final _perCodeStatusController = TextEditingController();
  final _generatedAtController = TextEditingController();
  final _notesController = TextEditingController();
  final _displayHintController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _oneTime = false;
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
      final dao = await ref.read(recoveryCodesDaoProvider.future);
      final row = await dao.getById(widget.recoveryCodesId!);
      if (row == null) return;
      final item = row.$1;
      final data = row.$2;

      _nameController.text = item.name;
      _codesBlobController.text = data.codesBlob;
      _codesCountController.text = data.codesCount?.toString() ?? '';
      _usedCountController.text = data.usedCount?.toString() ?? '';
      _perCodeStatusController.text = data.perCodeStatus ?? '';
      _generatedAtController.text = data.generatedAt?.toIso8601String() ?? '';
      _notesController.text = data.notes ?? '';
      _displayHintController.text = data.displayHint ?? '';
      _descriptionController.text = item.description ?? '';
      _oneTime = data.oneTime;
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codesBlobController.dispose();
    _codesCountController.dispose();
    _usedCountController.dispose();
    _perCodeStatusController.dispose();
    _generatedAtController.dispose();
    _notesController.dispose();
    _displayHintController.dispose();
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
      final dao = await ref.read(recoveryCodesDaoProvider.future);

      String? clean(TextEditingController controller) {
        final value = controller.text.trim();
        return value.isEmpty ? null : value;
      }

      final name = _nameController.text.trim();
      final codesBlob = _codesBlobController.text.trim();

      if (widget.isEdit) {
        await dao.updateRecoveryCodes(
          widget.recoveryCodesId!,
          UpdateRecoveryCodesDto(
            name: name,
            codesBlob: codesBlob,
            codesCount: _parseInt(_codesCountController.text),
            usedCount: _parseInt(_usedCountController.text),
            perCodeStatus: clean(_perCodeStatusController),
            generatedAt: _parseDate(_generatedAtController.text),
            notes: clean(_notesController),
            oneTime: _oneTime,
            displayHint: clean(_displayHintController),
            description: clean(_descriptionController),
          ),
        );
      } else {
        await dao.createRecoveryCodes(
          CreateRecoveryCodesDto(
            name: name,
            codesBlob: codesBlob,
            codesCount: _parseInt(_codesCountController.text),
            usedCount: _parseInt(_usedCountController.text),
            perCodeStatus: clean(_perCodeStatusController),
            generatedAt: _parseDate(_generatedAtController.text),
            notes: clean(_notesController),
            oneTime: _oneTime,
            displayHint: clean(_displayHintController),
            description: clean(_descriptionController),
          ),
        );
      }

      Toaster.success(
        title: widget.isEdit
            ? 'Коды восстановления обновлены'
            : 'Коды восстановления созданы',
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
          widget.isEdit
              ? 'Редактировать коды восстановления'
              : 'Новые коды восстановления',
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
                    controller: _codesBlobController,
                    decoration: const InputDecoration(labelText: 'Codes blob'),
                    minLines: 4,
                    maxLines: 8,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Codes blob обязателен'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codesCountController,
                    decoration: const InputDecoration(labelText: 'Всего кодов'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usedCountController,
                    decoration: const InputDecoration(
                      labelText: 'Использовано',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _perCodeStatusController,
                    decoration: const InputDecoration(
                      labelText: 'Per-code status JSON',
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _generatedAtController,
                    decoration: const InputDecoration(
                      labelText: 'Generated at (ISO8601)',
                    ),
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
                    controller: _displayHintController,
                    decoration: const InputDecoration(
                      labelText: 'Display hint',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Описание'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  SwitchListTile(
                    value: _oneTime,
                    onChanged: (v) => setState(() => _oneTime = v),
                    title: const Text('Одноразовые коды'),
                  ),
                ],
              ),
            ),
    );
  }
}
