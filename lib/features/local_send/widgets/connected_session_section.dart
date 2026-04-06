import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/local_send/models/encrypted_transfer_envelope.dart';
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:hoplixi/features/local_send/models/history_item.dart';
import 'package:hoplixi/features/local_send/providers/session_history_provider.dart';
import 'package:hoplixi/features/local_send/providers/transfer_provider.dart';
import 'package:hoplixi/features/local_send/utils/platform_icons.dart';
import 'package:hoplixi/features/local_send/widgets/import_cloud_sync_tokens_dialog.dart';
import 'package:hoplixi/features/local_send/widgets/import_store_archive_dialog.dart';
import 'package:hoplixi/features/local_send/widgets/send_cloud_sync_tokens_dialog.dart';
import 'package:hoplixi/features/local_send/widgets/send_store_dialog.dart';
import 'package:hoplixi/main_store/services/archive_service.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:open_file/open_file.dart' as open_file;

class ConnectedSessionSection extends ConsumerStatefulWidget {
  final DeviceInfo peer;

  const ConnectedSessionSection({super.key, required this.peer});

  @override
  ConsumerState<ConnectedSessionSection> createState() =>
      _ConnectedSessionSectionState();
}

class _ConnectedSessionSectionState
    extends ConsumerState<ConnectedSessionSection> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DropTarget(
      onDragDone: (detail) async {
        final files = detail.files.map((f) => File(f.path)).toList();
        if (files.isNotEmpty) {
          await ref.read(transferProvider.notifier).sendFiles(files);
        }
      },
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      child: Stack(
        children: [
          Column(
            children: [
              // Верхняя часть: пир + действия.
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConnectedPeerCard(
                      widget.peer,
                      colorScheme,
                      textTheme,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Отправить',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactAction(
                            icon: Icons.attach_file,
                            label: 'Файлы',
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            onTap: _pickAndSendFiles,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCompactAction(
                            icon: Icons.text_fields,
                            label: 'Текст',
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            onTap: _showSendTextDialog,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactAction(
                            icon: Icons.inventory_2_outlined,
                            label: 'Хранилище',
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            onTap: _showSendStoreDialog,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCompactAction(
                            icon: Icons.key_outlined,
                            label: 'OAuth токены',
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            onTap: _showSendCloudSyncTokensDialog,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // История обмена — скроллируемая.
              Expanded(child: _buildHistoryList(colorScheme, textTheme)),

              // Кнопка отключения — закреплена внизу.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  MediaQuery.paddingOf(context).bottom + 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SmoothButton(
                    onPressed: () {
                      ref.read(transferProvider.notifier).disconnect();
                    },
                    icon: const Icon(Icons.link_off),
                    label: 'Отключиться',
                    variant: .error,
                  ),
                ),
              ),
            ],
          ),
          if (_dragging)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Отпустите для отправки',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactAction({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedPeerCard(
    DeviceInfo peer,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              getPlatformIcon(peer.platform),
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, color: colorScheme.primary, size: 8),
                    const SizedBox(width: 6),
                    Text(
                      'Подключено • ${peer.ip}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(ColorScheme colorScheme, TextTheme textTheme) {
    final history = ref.watch(sessionHistoryProvider);

    if (history.isEmpty) {
      return Center(
        child: Text(
          'История обмена пуста',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'История обмена',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: history.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              // reversed list
              itemBuilder: (context, index) {
                final item = history[history.length - 1 - index];
                return _buildHistoryTile(item, colorScheme, textTheme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(
    HistoryItem item,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final icon = item.isFile
        ? (item.isSent ? Icons.upload_file : Icons.download)
        : item.isAuthTokenPayload
        ? (item.isSent ? Icons.key_outlined : Icons.key)
        : (item.isSent ? Icons.send : Icons.message);

    final directionLabel = item.isSent ? 'Отправлено' : 'Получено';

    final iconColor = item.isSent ? colorScheme.primary : colorScheme.tertiary;
    final deviceName = item.deviceName?.trim();
    final hasDeviceName = deviceName != null && deviceName.isNotEmpty;

    final time =
        '${item.timestamp.hour.toString().padLeft(2, '0')}'
        ':${item.timestamp.minute.toString().padLeft(2, '0')}';

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleHistoryItemTap(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.content,
                      style: textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasDeviceName)
                      Text(
                        deviceName,
                        style: textTheme.bodySmall?.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      '$directionLabel • $time',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_shouldShowTrailingAction(item))
                Icon(
                  _trailingIconForItem(item),
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    final files = <File>[];
    for (final platformFile in result.files) {
      if (platformFile.path != null) {
        files.add(File(platformFile.path!));
      }
    }

    if (files.isNotEmpty && mounted) {
      await ref.read(transferProvider.notifier).sendFiles(files);
    }
  }

  Future<void> _showSendTextDialog() async {
    if (!mounted) return;

    final text = await showDialog<String>(
      context: context,
      builder: (context) => const _SendTextDialog(),
    );

    if (text != null && text.trim().isNotEmpty && mounted) {
      await ref.read(transferProvider.notifier).sendText(text.trim());
    }
  }

  Future<void> _showSendStoreDialog() async {
    if (!mounted) return;

    final result = await showDialog<SendStoreDialogResult>(
      context: context,
      builder: (context) => const SendStoreDialog(),
    );

    if (result == null || !mounted) {
      return;
    }

    await ref
        .read(transferProvider.notifier)
        .sendStoreArchive(result.store, password: result.archivePassword);
  }

  Future<void> _showSendCloudSyncTokensDialog() async {
    if (!mounted) return;

    final result = await showDialog<SendCloudSyncTokensDialogResult>(
      context: context,
      builder: (context) => const SendCloudSyncTokensDialog(),
    );

    if (result == null || !mounted) {
      return;
    }

    await ref
        .read(transferProvider.notifier)
        .sendCloudSyncTokens(
          result.tokens,
          password: result.password,
          exportMode: result.exportMode,
        );
  }

  Future<void> _handleHistoryItemTap(HistoryItem item) async {
    if (item.isAuthTokenPayload &&
        !item.isSent &&
        item.encryptedEnvelope != null) {
      await _showImportCloudSyncTokensDialog(
        item.encryptedEnvelope!,
        item.deviceName,
      );
      return;
    }

    if (item.isFile && item.filePath != null) {
      if (!item.isSent && ArchiveService.isStoreArchiveFile(item.filePath!)) {
        await _showImportStoreArchiveDialog(item.filePath!);
        return;
      }

      await open_file.OpenFile.open(item.filePath!);
      return;
    }

    if (item.isText) {
      await Clipboard.setData(ClipboardData(text: item.content));
      Toaster.info(title: 'Текст скопирован в буфер обмена');
    }
  }

  Future<void> _showImportStoreArchiveDialog(String archivePath) async {
    await showStoreArchiveImportDialog(context, ref, archivePath: archivePath);
  }

  Future<void> _showImportCloudSyncTokensDialog(
    EncryptedTransferEnvelope envelope,
    String? deviceName,
  ) async {
    await showCloudSyncTokensImportDialog(
      context,
      ref,
      envelope: envelope,
      deviceName: deviceName,
    );
  }

  bool _shouldShowTrailingAction(HistoryItem item) {
    if (item.isFile) {
      return item.filePath != null;
    }

    return item.isText || (item.isAuthTokenPayload && !item.isSent);
  }

  IconData _trailingIconForItem(HistoryItem item) {
    if (item.isFile) {
      return Icons.folder_open;
    }

    if (item.isAuthTokenPayload) {
      return Icons.download_for_offline_outlined;
    }

    return Icons.copy;
  }
}

class _SendTextDialog extends StatefulWidget {
  const _SendTextDialog();

  @override
  State<_SendTextDialog> createState() => _SendTextDialogState();
}

class _SendTextDialogState extends State<_SendTextDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    // Запрашиваем фокус после завершения build-фазы диалога,
    // чтобы не получить visitChildElements() called during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(12),
      title: const Text('Отправить текст'),
      content: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: 5,
        minLines: 1,
        decoration: primaryInputDecoration(
          context,
          labelText: 'Введите текст для отправки',
        ),
      ),
      actions: [
        SmoothButton(
          onPressed: () => Navigator.pop(context),
          label: 'Отмена',
          type: .text,
        ),
        SmoothButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          label: 'Отправить',
          type: .filled,
        ),
      ],
    );
  }
}
