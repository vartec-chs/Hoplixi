import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class SshKeyFormScreen extends ConsumerStatefulWidget {
  const SshKeyFormScreen({super.key, this.sshKeyId});

  final String? sshKeyId;

  bool get isEdit => sshKeyId != null;

  @override
  ConsumerState<SshKeyFormScreen> createState() => _SshKeyFormScreenState();
}

class _SshKeyFormScreenState extends ConsumerState<SshKeyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _publicKeyController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _keyTypeController = TextEditingController();
  final _fingerprintController = TextEditingController();
  final _usageController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _addedToAgent = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(sshKeyDaoProvider.future);
      final row = await dao.getById(widget.sshKeyId!);
      if (row == null) return;
      final item = row.$1;
      final ssh = row.$2;
      _nameController.text = item.name;
      _publicKeyController.text = ssh.publicKey;
      _privateKeyController.text = ssh.privateKey;
      _keyTypeController.text = ssh.keyType ?? '';
      _fingerprintController.text = ssh.fingerprint ?? '';
      _usageController.text = ssh.usage ?? '';
      _descriptionController.text = item.description ?? '';
      _addedToAgent = ssh.addedToAgent;
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _publicKeyController.dispose();
    _privateKeyController.dispose();
    _keyTypeController.dispose();
    _fingerprintController.dispose();
    _usageController.dispose();
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
      final dao = await ref.read(sshKeyDaoProvider.future);

      final name = _nameController.text.trim();
      final publicKey = _publicKeyController.text.trim();
      final privateKey = _privateKeyController.text.trim();
      final keyType = _keyTypeController.text.trim();
      final fingerprint = _fingerprintController.text.trim();
      final usage = _usageController.text.trim();
      final description = _descriptionController.text.trim();

      if (widget.isEdit) {
        await dao.updateSshKey(
          widget.sshKeyId!,
          UpdateSshKeyDto(
            name: name,
            publicKey: publicKey,
            privateKey: privateKey,
            keyType: keyType.isEmpty ? null : keyType,
            fingerprint: fingerprint.isEmpty ? null : fingerprint,
            usage: usage.isEmpty ? null : usage,
            description: description.isEmpty ? null : description,
            addedToAgent: _addedToAgent,
          ),
        );
      } else {
        await dao.createSshKey(
          CreateSshKeyDto(
            name: name,
            publicKey: publicKey,
            privateKey: privateKey,
            keyType: keyType.isEmpty ? null : keyType,
            fingerprint: fingerprint.isEmpty ? null : fingerprint,
            usage: usage.isEmpty ? null : usage,
            description: description.isEmpty ? null : description,
            addedToAgent: _addedToAgent,
          ),
        );
      }

      Toaster.success(
        title: widget.isEdit ? 'SSH-ключ обновлен' : 'SSH-ключ создан',
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
          widget.isEdit ? 'Редактировать SSH-ключ' : 'Новый SSH-ключ',
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
                    controller: _publicKeyController,
                    decoration: const InputDecoration(labelText: 'Public key'),
                    minLines: 2,
                    maxLines: 5,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Public key обязателен'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _privateKeyController,
                    decoration: const InputDecoration(labelText: 'Private key'),
                    minLines: 2,
                    maxLines: 6,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Private key обязателен'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _keyTypeController,
                    decoration: const InputDecoration(labelText: 'Тип ключа'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fingerprintController,
                    decoration: const InputDecoration(labelText: 'Fingerprint'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usageController,
                    decoration: const InputDecoration(
                      labelText: 'Использование',
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
                    value: _addedToAgent,
                    onChanged: (v) => setState(() => _addedToAgent = v),
                    title: const Text('Добавлен в ssh-agent'),
                  ),
                ],
              ),
            ),
    );
  }
}
