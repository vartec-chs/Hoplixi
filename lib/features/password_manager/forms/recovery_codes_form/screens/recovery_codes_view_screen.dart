import 'package:hoplixi/shared/ui/background_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/features/password_manager/shared/utils/copy_usage_utils.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_view_section.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/vault_db/core/models/dto/recovery_codes_dto.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
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
  bool _isDeleted = false;

  String _name = '';
  bool _oneTime = false;
  String? _description;
  List<RecoveryCodeValueDto> _codes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repos = await ref.read(vaultRepositories.future);
      final viewResult = await repos.recoveryCodes.getViewById(
        widget.recoveryCodesId,
      );
      final view = viewResult.getOrNull()?.getOrNull();
      if (view == null) {
        if (mounted) {
          Toaster.error(
            title: context.t.dashboard_forms.common_record_not_found,
          );
          context.pop();
        }
        return;
      }
      final item = view.item;
      final recoveryCodes = view.recoveryCodes;

      setState(() {
        _isDeleted = item.isDeleted;
        _name = item.name;
        _oneTime = recoveryCodes.oneTime;
        _description = item.description;
        _codes = view.codes;
      });
    } catch (e) {
      if (mounted) {
        Toaster.error(
          title: context.t.dashboard_forms.common_load_error,
          description: '$e',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalCount => _codes.length;
  int get _usedCount => _codes.where((c) => c.used).length;

  Future<void> _markUsed(RecoveryCodeValueDto code) async {
    final id = code.id;
    if (id == null) return;
    final repos = await ref.read(vaultRepositories.future);
    await repos.recoveryCodes.markCodeUsed(codeId: id, usedAt: DateTime.now());
    if (mounted) {
      Toaster.success(title: context.t.dashboard_forms.code_marked_used);
      await _load();
    }
  }

  Future<void> _markUnused(RecoveryCodeValueDto code) async {
    final id = code.id;
    if (id == null) return;
    final repos = await ref.read(vaultRepositories.future);
    await repos.recoveryCodes.markCodeUnused(codeId: id);
    if (mounted) {
      Toaster.success(title: context.t.dashboard_forms.code_marked_unused);
      await _load();
    }
  }

  Future<void> _copyCode(String code) async {
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.recoveryCodesId,
      text: code,
    );
    if (!copied) return;
    if (mounted) Toaster.success(title: context.t.dashboard_forms.code_copied);
  }

  Future<void> _copyNextUnused() async {
    final next = _codes.where((c) => !c.used).firstOrNull;
    if (next == null) {
      Toaster.error(title: context.t.dashboard_forms.no_codes_yet);
      return;
    }
    await _copyCode(next.code);
    if (_oneTime) {
      await _markUsed(next);
    }
  }

  Future<void> _deleteCode(RecoveryCodeValueDto code) async {
    final id = code.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t.dashboard_forms.delete_code_label),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t.dashboard_forms.clear),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repos = await ref.read(vaultRepositories.future);
    await repos.recoveryCodes.deleteCode(id);
    if (mounted) await _load();
  }

  Future<void> _share() async {
    final l10n = context.t.dashboard_forms;
    final customFields = await loadCustomShareableFields(
      ref,
      widget.recoveryCodesId,
    );
    if (!mounted) return;

    final codesText = _codes
        .map(
          (code) =>
              '${code.code} - ${code.used ? l10n.code_used_label : l10n.code_unused_label}',
        )
        .join('\n');
    final fields = [
      ...compactShareableFields([
        shareableField(id: 'name', label: l10n.share_name_label, value: _name),
        shareableField(
          id: 'codes_count',
          label: l10n.total_codes_label,
          value: _totalCount,
        ),
        shareableField(
          id: 'used_count',
          label: l10n.used_codes_label,
          value: _usedCount,
        ),
        shareableField(
          id: 'one_time',
          label: l10n.one_time_codes_label,
          value: _oneTime ? l10n.common_enabled : l10n.common_disabled,
        ),
        shareableField(
          id: 'description',
          label: l10n.description_label,
          value: _description,
        ),
        shareableField(
          id: 'codes',
          label: l10n.codes_label,
          value: codesText,
          isSensitive: true,
        ),
      ]),
      ...customFields,
    ];

    await shareEntityFields(
      context: context,
      entity: ShareableEntity(
        title: _name,
        entityTypeLabel: EntityType.recoveryCodes.label,
        fields: fields,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.dashboard_forms;

    return Scaffold(
      backgroundColor: getScreenBackgroundColor(context, ref),
      appBar: AppBar(
        title: Text(l10n.view_recovery_codes),
        actions: [
          IconButton(
            tooltip: l10n.share_action,
            onPressed: _loading || _isDeleted ? null : _share,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            tooltip: l10n.edit,
            onPressed: _isDeleted
                ? null
                : () => context
                      .push(
                        AppRoutesPaths.dashboardEntityEdit(
                          EntityType.recoveryCodes,
                          widget.recoveryCodesId,
                        ),
                      )
                      .then((_) => _load()),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Шапка / статистика
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _StatChip(
                              icon: Icons.list_alt,
                              label: '$_usedCount / $_totalCount',
                            ),
                            const SizedBox(width: 8),
                            _StatChip(
                              icon: _oneTime ? Icons.looks_one : Icons.repeat,
                              label: _oneTime
                                  ? l10n.one_time_codes_label
                                  : 'multi-use',
                            ),
                          ],
                        ),
                        if (_description?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            _description!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        CustomFieldsViewSection(itemId: widget.recoveryCodesId),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _usedCount < _totalCount
                                ? _copyNextUnused
                                : null,
                            icon: const Icon(Icons.copy),
                            label: Text(l10n.copy_code_action),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Список кодов
                  Expanded(
                    child: _codes.isEmpty
                        ? Center(child: Text(l10n.no_codes_yet))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _codes.length,
                            itemBuilder: (ctx, i) {
                              final code = _codes[i];
                              return _CodeListTile(
                                code: code,
                                onCopy: () => _copyCode(code.code),
                                onMarkUsed: code.used
                                    ? null
                                    : () => _markUsed(code),
                                onMarkUnused: code.used
                                    ? () => _markUnused(code)
                                    : null,
                                onDelete: () => _deleteCode(code),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _CodeListTile extends StatelessWidget {
  const _CodeListTile({
    required this.code,
    required this.onCopy,
    this.onMarkUsed,
    this.onMarkUnused,
    required this.onDelete,
  });

  final RecoveryCodeValueDto code;
  final VoidCallback onCopy;
  final VoidCallback? onMarkUsed;
  final VoidCallback? onMarkUnused;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.dashboard_forms;
    final used = code.used;
    final textStyle = used
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: Theme.of(context).colorScheme.outline,
          )
        : Theme.of(context).textTheme.bodyMedium;

    return ListTile(
      dense: true,
      leading: SizedBox(
        width: 32,
        child: used
            ? Icon(
                Icons.check_circle,
                size: 20,
                color: Theme.of(context).colorScheme.outline,
              )
            : Icon(
                Icons.radio_button_unchecked,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
      ),
      title: Text(code.code, style: textStyle),
      subtitle: (code.usedAt != null && used)
          ? Text(
              code.usedAt!.toLocal().toString().substring(0, 16),
              style: Theme.of(context).textTheme.labelSmall,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!used)
            IconButton(
              tooltip: l10n.copy_code_action,
              icon: const Icon(Icons.copy, size: 18),
              onPressed: onCopy,
            ),
          if (onMarkUsed != null)
            IconButton(
              tooltip: l10n.mark_code_used_action,
              icon: const Icon(Icons.check, size: 18),
              onPressed: onMarkUsed,
            ),
          if (onMarkUnused != null)
            IconButton(
              tooltip: l10n.mark_code_unused_action,
              icon: const Icon(Icons.undo, size: 18),
              onPressed: onMarkUnused,
            ),
          IconButton(
            tooltip: l10n.delete_code_label,
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
