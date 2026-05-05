import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/local_send/providers/local_send_buffer_provider.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_text_formatter.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

typedef ShareTextInvoker = Future<ShareResult> Function(ShareParams params);

Future<void> showShareFieldsDialog({
  required BuildContext context,
  required ShareableEntity entity,
  ShareTextInvoker? share,
}) async {
  final l10n = context.t.dashboard_forms;
  final fields = entity.nonEmptyFields;

  if (fields.isEmpty) {
    Toaster.warning(title: l10n.share_no_fields);
    return;
  }

  await WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        hasSabGradient: false,
        topBarTitle: Text(
          l10n.share_dialog_title,
          style: Theme.of(modalContext).textTheme.titleMedium,
        ),
        isTopBarLayerAlwaysVisible: true,
        leadingNavBarWidget: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(modalContext).pop(),
          ),
        ),
        child: _ShareFieldsContent(
          entity: entity,
          fields: fields,
          share: share ?? SharePlus.instance.share,
        ),
      ),
    ],
  );
}

class _ShareFieldsContent extends StatefulWidget {
  const _ShareFieldsContent({
    required this.entity,
    required this.fields,
    required this.share,
  });

  final ShareableEntity entity;
  final List<ShareableField> fields;
  final ShareTextInvoker share;

  @override
  State<_ShareFieldsContent> createState() => _ShareFieldsContentState();
}

class _ShareFieldsContentState extends State<_ShareFieldsContent> {
  late final Set<String> _selectedIds;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.fields
        .where((field) => !field.isSensitive)
        .map((field) => field.id)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.dashboard_forms;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 600;
    final listHeight = (widget.fields.length * (isCompact ? 76.0 : 72.0)).clamp(
      120.0,
      size.height * 0.55,
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              widget.entity.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              itemCount: widget.fields.length,
              itemBuilder: (context, index) {
                final field = widget.fields[index];

                return CheckboxListTile(
                  value: _selectedIds.contains(field.id),
                  onChanged: _isSharing
                      ? null
                      : (value) => _toggleField(field.id, value: value),
                  title: Text(field.label),
                  subtitle: field.isSensitive
                      ? Text(l10n.share_sensitive_field_hint)
                      : null,
                  secondary: field.isSensitive
                      ? const Icon(LucideIcons.lockKeyhole)
                      : const Icon(LucideIcons.textCursor),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SmoothButton(
                  onPressed: _isSharing ? null : _clearSelection,
                  type: SmoothButtonType.text,
                  label: l10n.share_clear_all_action,
                  isFullWidth: true,
                ),
                const SizedBox(height: 8),
                SmoothButton(
                  onPressed: _isSharing ? null : _selectAll,
                  type: SmoothButtonType.text,
                  label: l10n.share_select_all_action,
                  isFullWidth: true,
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    return SmoothButton(
                      onPressed: _isSharing
                          ? null
                          : () => _bufferSelection(ref),
                      type: SmoothButtonType.tonal,
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: 'В локальный буфер',
                      isFullWidth: true,
                    );
                  },
                ),
                const SizedBox(height: 8),
                SmoothButton(
                  onPressed: _isSharing
                      ? null
                      : () => Navigator.of(context).pop(),
                  type: SmoothButtonType.text,
                  label: l10n.share_cancel_action,
                  isFullWidth: true,
                ),
                const SizedBox(height: 8),
                SmoothButton(
                  onPressed: _selectedIds.isEmpty || _isSharing ? null : _share,
                  type: SmoothButtonType.filled,
                  icon: const Icon(LucideIcons.share2),
                  label: l10n.share_action,
                  loading: _isSharing,
                  isFullWidth: true,
                ),
              ],
            )
          else
            Column(
              spacing: 8,

              children: [
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: SmoothButton(
                        onPressed: _isSharing ? null : _clearSelection,
                        type: SmoothButtonType.text,
                        label: l10n.share_clear_all_action,
                      ),
                    ),
                    Expanded(
                      child: SmoothButton(
                        onPressed: _isSharing ? null : _selectAll,
                        type: SmoothButtonType.text,
                        label: l10n.share_select_all_action,
                      ),
                    ),
                  ],
                ),

                Row(
                  spacing: 8,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        return Expanded(
                          child: SmoothButton(
                            onPressed: _isSharing
                                ? null
                                : () => _bufferSelection(ref),
                            type: SmoothButtonType.tonal,
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: 'В локальный буфер',
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: SmoothButton(
                        onPressed: _isSharing
                            ? null
                            : () => Navigator.of(context).pop(),
                        type: SmoothButtonType.text,
                        label: l10n.share_cancel_action,
                      ),
                    ),
                    Expanded(
                      child: SmoothButton(
                        onPressed: _selectedIds.isEmpty || _isSharing
                            ? null
                            : _share,
                        type: SmoothButtonType.filled,
                        icon: const Icon(LucideIcons.share2),
                        label: l10n.share_action,
                        loading: _isSharing,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _bufferSelection(WidgetRef ref) {
    final selectedFields = _selectedFields();
    if (selectedFields.isEmpty) {
      return;
    }

    ref.read(localSendBufferProvider.notifier).addToBuffer(selectedFields);
    Toaster.success(title: 'Поля сохранены в локальный буфер');
  }

  List<ShareableField> _selectedFields() {
    return widget.fields
        .where((field) => _selectedIds.contains(field.id))
        .toList(growable: false);
  }

  void _toggleField(String id, {required bool? value}) {
    setState(() {
      if (value ?? false) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(widget.fields.map((field) => field.id));
    });
  }

  void _clearSelection() {
    setState(_selectedIds.clear);
  }

  Future<void> _share() async {
    final selectedFields = _selectedFields();
    final text = buildShareTextFromFields(
      selectedFields,
      title: widget.entity.title,
    );
    setState(() => _isSharing = true);

    try {
      await widget.share(ShareParams(text: text, subject: widget.entity.title));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      logError(
        'Ошибка при попытке поделиться полями записи',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      Toaster.error(title: context.t.dashboard_forms.share_error);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}
