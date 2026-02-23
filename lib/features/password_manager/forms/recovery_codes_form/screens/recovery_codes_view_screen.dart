import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/generated/l10n.dart';
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
        Toaster.error(title: S.of(context).commonRecordNotFound);
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
        _oneTime = data.oneTime;
        _displayHint = data.displayHint;
        _description = item.description;
      });
    } catch (e) {
      Toaster.error(title: S.of(context).commonLoadError, description: '$e');
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
    final l10n = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewRecoveryCodes),
        actions: [
          IconButton(
            tooltip: l10n.edit,
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
                  title: Text(l10n.totalCodesLabel),
                  subtitle: Text('${_codesCount ?? '-'}'),
                ),
                ListTile(
                  title: Text(l10n.usedCodesLabel),
                  subtitle: Text('${_usedCount ?? '-'}'),
                ),
                ListTile(
                  title: Text(l10n.generatedAtIsoLabel),
                  subtitle: Text(_fmt(_generatedAt)),
                ),
                ListTile(
                  title: Text(l10n.oneTimeCodesLabel),
                  subtitle: Text(_oneTime ? l10n.commonYes : l10n.commonNo),
                ),
                if (_displayHint?.isNotEmpty == true)
                  ListTile(
                    title: Text(l10n.displayHintLabel),
                    subtitle: Text(_displayHint!),
                  ),
                if (_perCodeStatus?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.perCodeStatusJsonLabel),
                    subtitle: SelectableText(_perCodeStatus!),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.codesBlobRequiredLabel),
                  subtitle: SelectableText(_codesBlob),
                ),
                if (_description?.isNotEmpty == true)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.descriptionLabel),
                    subtitle: Text(_description!),
                  ),
              ],
            ),
    );
  }
}
