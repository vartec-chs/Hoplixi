import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/shared/utils/copy_usage_utils.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/main_db/core/models/dto/recovery_code_item_dto.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/widgets/custom_fields_view_section.dart';

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
  int _codesCount = 0;
  int _usedCount = 0;
  bool _oneTime = false;
  String? _displayHint;
  String? _description;
  List<RecoveryCodeItemDto> _codes = [];

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
        Toaster.error(title: context.t.dashboard_forms.common_record_not_found);
        if (mounted) context.pop();
        return;
      }
      final item = row.$1;
      final data = row.$2;

      final codesRaw = await dao.getCodesForItem(widget.recoveryCodesId);
      final codes = codesRaw
          .map(
            (c) => RecoveryCodeItemDto(
              id: c.id,
              itemId: c.itemId,
              code: c.code,
              used: c.used,
              usedAt: c.usedAt,
              position: c.position,
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _name = item.name;
        _codesCount = data.codesCount;
        _usedCount = data.usedCount;
        _oneTime = data.oneTime;
        _displayHint = data.displayHint;
        _description = item.description;
        _codes = codes;
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

  Future<void> _markUsed(RecoveryCodeItemDto code) async {
    final dao = await ref.read(recoveryCodesDaoProvider.future);
    await dao.markCodeUsed(code.id);
    Toaster.success(title: context.t.dashboard_forms.code_marked_used);
    await _load();
  }

  Future<void> _markUnused(RecoveryCodeItemDto code) async {
    final dao = await ref.read(recoveryCodesDaoProvider.future);
    await dao.markCodeUnused(code.id);
    Toaster.success(title: context.t.dashboard_forms.code_marked_unused);
    await _load();
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

  Future<void> _deleteCode(RecoveryCodeItemDto code) async {
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

    final dao = await ref.read(recoveryCodesDaoProvider.future);
    await dao.deleteCode(code.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.dashboard_forms;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.view_recovery_codes),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => context
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
                  // Ð¨Ð°Ð¿ÐºÐ° / ÑÑ‚Ð°Ñ‚Ð¸ÑÑ‚Ð¸ÐºÐ°
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
                              label: '$_usedCount / $_codesCount',
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
                        if (_displayHint?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.display_hint_label}: $_displayHint',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (_description?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            _description!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        CustomFieldsViewSection(itemId: widget.recoveryCodesId),
                        const SizedBox(height: 12),
                        // ÐšÐ½Ð¾Ð¿ÐºÐ° Ð±Ñ‹ÑÑ‚Ñ€Ð¾Ð³Ð¾ ÐºÐ¾Ð¿Ð¸Ñ€Ð¾Ð²Ð°Ð½Ð¸Ñ ÑÐ»ÐµÐ´ÑƒÑŽÑ‰ÐµÐ³Ð¾ Ð½ÐµÐ¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð½Ð¾Ð³Ð¾
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _usedCount < _codesCount
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
                  // Ð¡Ð¿Ð¸ÑÐ¾Ðº ÐºÐ¾Ð´Ð¾Ð²
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

  final RecoveryCodeItemDto code;
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
          // ÐšÐ¾Ð¿Ð¸Ñ€Ð¾Ð²Ð°Ñ‚ÑŒ
          if (!used)
            IconButton(
              tooltip: l10n.copy_code_action,
              icon: const Icon(Icons.copy, size: 18),
              onPressed: onCopy,
            ),
          // ÐžÑ‚Ð¼ÐµÑ‚Ð¸Ñ‚ÑŒ Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð½Ñ‹Ð¼ / ÑÐ½ÑÑ‚ÑŒ
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
          // Ð£Ð´Ð°Ð»Ð¸Ñ‚ÑŒ
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
