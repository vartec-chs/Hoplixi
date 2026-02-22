import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

class RecoveryCodesViewScreen extends ConsumerStatefulWidget {
  const RecoveryCodesViewScreen({super.key, required this.recoveryCodesId});

  final String recoveryCodesId;

  @override
  ConsumerState<RecoveryCodesViewScreen> createState() =>
      _RecoveryCodesViewScreenState();
}

class _RecoveryCodesViewScreenState
    extends ConsumerState<RecoveryCodesViewScreen> {
  bool _loading = true;

  String _name = '';
  String _codesBlob = '';
  int? _codesCount;
  int? _usedCount;
  String? _perCodeStatus;
  DateTime? _generatedAt;
  String? _notes;
  bool _oneTime = false;
  String? _displayHint;
  String? _description;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dao = await ref.read(recoveryCodesDaoProvider.future);
      final row = await dao.getById(widget.recoveryCodesId);
      if (row == null) {
        Toaster.error(title: 'Запись не найдена');
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final data = row.$2;

      setState(() {
        _name = item.name;
        _codesBlob = data.codesBlob;
        _codesCount = data.codesCount;
        _usedCount = data.usedCount;
        _perCodeStatus = data.perCodeStatus;
        _generatedAt = data.generatedAt;
        _notes = data.notes;
        _oneTime = data.oneTime;
        _displayHint = data.displayHint;
        _description = item.description;
      });
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime? value) {
    if (value == null) return '-';
    return value.toIso8601String();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Просмотр кодов восстановления'),
        actions: [
          IconButton(
            tooltip: 'Редактировать',
            onPressed: () => context.push(
              AppRoutesPaths.dashboardEntityEdit(
                EntityType.recoveryCodes,
                widget.recoveryCodesId,
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
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Кодов всего'),
                  subtitle: Text('${_codesCount ?? '-'}'),
                ),
                ListTile(
                  title: const Text('Кодов использовано'),
                  subtitle: Text('${_usedCount ?? '-'}'),
                ),
                ListTile(
                  title: const Text('Generated at'),
                  subtitle: Text(_fmt(_generatedAt)),
                ),
                ListTile(
                  title: const Text('Одноразовые'),
                  subtitle: Text(_oneTime ? 'Да' : 'Нет'),
                ),
                if (_displayHint?.isNotEmpty == true)
                  ListTile(
                    title: const Text('Display hint'),
                    subtitle: Text(_displayHint!),
                  ),
                if (_notes?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Заметки'),
                    subtitle: Text(_notes!),
                  ),
                if (_perCodeStatus?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Per-code status'),
                    subtitle: SelectableText(_perCodeStatus!),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Codes blob'),
                  subtitle: SelectableText(_codesBlob),
                ),
                if (_description?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Описание'),
                    subtitle: Text(_description!),
                  ),
              ],
            ),
    );
  }
}
