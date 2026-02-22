import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class ApiKeyFormScreen extends ConsumerStatefulWidget {
  const ApiKeyFormScreen({super.key, this.apiKeyId});

  final String? apiKeyId;

  bool get isEdit => apiKeyId != null;

  @override
  ConsumerState<ApiKeyFormScreen> createState() => _ApiKeyFormScreenState();
}

class _ApiKeyFormScreenState extends ConsumerState<ApiKeyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _serviceController = TextEditingController();
  final _keyController = TextEditingController();
  final _tokenTypeController = TextEditingController();
  final _environmentController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _revoked = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(apiKeyDaoProvider.future);
      final row = await dao.getById(widget.apiKeyId!);
      if (row == null) return;
      final item = row.$1;
      final details = row.$2;
      _nameController.text = item.name;
      _serviceController.text = details.service;
      _keyController.text = details.key;
      _tokenTypeController.text = details.tokenType ?? '';
      _environmentController.text = details.environment ?? '';
      _descriptionController.text = item.description ?? '';
      _revoked = details.revoked;
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serviceController.dispose();
    _keyController.dispose();
    _tokenTypeController.dispose();
    _environmentController.dispose();
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
      final dao = await ref.read(apiKeyDaoProvider.future);
      final name = _nameController.text.trim();
      final service = _serviceController.text.trim();
      final key = _keyController.text.trim();
      final tokenType = _tokenTypeController.text.trim();
      final environment = _environmentController.text.trim();
      final description = _descriptionController.text.trim();

      if (widget.isEdit) {
        await dao.updateApiKey(
          widget.apiKeyId!,
          UpdateApiKeyDto(
            name: name,
            description: description.isEmpty ? null : description,
            service: service,
            key: key,
            tokenType: tokenType.isEmpty ? null : tokenType,
            environment: environment.isEmpty ? null : environment,
            revoked: _revoked,
            maskedKey: key.length > 6
                ? '${key.substring(0, 3)}•••${key.substring(key.length - 3)}'
                : '••••••',
          ),
        );
      } else {
        await dao.createApiKey(
          CreateApiKeyDto(
            name: name,
            service: service,
            key: key,
            description: description.isEmpty ? null : description,
            tokenType: tokenType.isEmpty ? null : tokenType,
            environment: environment.isEmpty ? null : environment,
            revoked: _revoked,
            maskedKey: key.length > 6
                ? '${key.substring(0, 3)}•••${key.substring(key.length - 3)}'
                : '••••••',
          ),
        );
      }

      Toaster.success(
        title: widget.isEdit ? 'API-ключ обновлен' : 'API-ключ создан',
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
          widget.isEdit ? 'Редактировать API-ключ' : 'Новый API-ключ',
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
                    controller: _serviceController,
                    decoration: const InputDecoration(labelText: 'Сервис'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Сервис обязателен'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _keyController,
                    decoration: const InputDecoration(labelText: 'Ключ'),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Ключ обязателен';
                      if (value.length < 8) return 'Минимум 8 символов';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tokenTypeController,
                    decoration: const InputDecoration(labelText: 'Тип токена'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _environmentController,
                    decoration: const InputDecoration(labelText: 'Окружение'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Описание'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _revoked,
                    onChanged: (v) => setState(() => _revoked = v),
                    title: const Text('Ключ отозван'),
                  ),
                ],
              ),
            ),
    );
  }
}
