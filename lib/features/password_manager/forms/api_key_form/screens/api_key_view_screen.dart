import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

class ApiKeyViewScreen extends ConsumerStatefulWidget {
  const ApiKeyViewScreen({super.key, required this.apiKeyId});

  final String apiKeyId;

  @override
  ConsumerState<ApiKeyViewScreen> createState() => _ApiKeyViewScreenState();
}

class _ApiKeyViewScreenState extends ConsumerState<ApiKeyViewScreen> {
  bool _loading = true;
  bool _revealingKey = false;
  String? _realKey;

  String _name = '';
  String _service = '';
  String? _maskedKey;
  String? _tokenType;
  String? _environment;
  String? _description;
  bool _revoked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(apiKeyDaoProvider.future);
      final row = await dao.getById(widget.apiKeyId);
      if (row == null) {
        Toaster.error(title: 'API-ключ не найден');
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final details = row.$2;
      setState(() {
        _name = item.name;
        _service = details.service;
        _maskedKey = details.maskedKey;
        _tokenType = details.tokenType;
        _environment = details.environment;
        _description = item.description;
        _revoked = details.revoked;
      });
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revealKey() async {
    if (_realKey != null) {
      setState(() => _revealingKey = !_revealingKey);
      return;
    }

    try {
      final dao = await ref.read(apiKeyDaoProvider.future);
      final key = await dao.getKeyFieldById(widget.apiKeyId);
      if (key == null) {
        Toaster.error(title: 'Не удалось получить ключ');
        return;
      }
      setState(() {
        _realKey = key;
        _revealingKey = true;
      });
    } catch (e) {
      Toaster.error(title: 'Ошибка получения ключа', description: '$e');
    }
  }

  Future<void> _copyKey() async {
    final value = _realKey ?? _maskedKey;
    if (value == null || value.isEmpty) {
      Toaster.warning(title: 'Ключ пуст');
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    Toaster.success(title: 'Ключ скопирован');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр API-ключа'),
        actions: [
          IconButton(
            tooltip: 'Редактировать',
            onPressed: () => context.push(
              AppRoutesPaths.dashboardEntityEdit(
                EntityType.apiKey,
                widget.apiKeyId,
              ),
            ),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(_name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(_service, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ключ'),
                  subtitle: Text(
                    _revealingKey
                        ? (_realKey ?? '')
                        : (_maskedKey ?? '••••••••'),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        onPressed: _revealKey,
                        icon: Icon(
                          _revealingKey
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      IconButton(
                        onPressed: _copyKey,
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                ),
                if (_tokenType?.isNotEmpty == true)
                  ListTile(
                    title: const Text('Тип токена'),
                    subtitle: Text(_tokenType!),
                  ),
                if (_environment?.isNotEmpty == true)
                  ListTile(
                    title: const Text('Окружение'),
                    subtitle: Text(_environment!),
                  ),
                ListTile(
                  title: const Text('Статус'),
                  subtitle: Text(_revoked ? 'Отозван' : 'Активен'),
                ),
                if (_description?.isNotEmpty == true)
                  ListTile(
                    title: const Text('Описание'),
                    subtitle: Text(_description!),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
    );
  }
}
