import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:hoplixi/features/local_send/models/history_item.dart';
import 'package:hoplixi/features/local_send/providers/session_history_provider.dart';
import 'package:hoplixi/features/local_send/providers/transfer_provider.dart';
import 'package:hoplixi/features/local_send/utils/platform_icons.dart';
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
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Верхняя часть: пир + действия.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConnectedPeerCard(widget.peer, colorScheme, textTheme),
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
        : (item.isSent ? Icons.send : Icons.message);

    final directionLabel = item.isSent ? 'Отправлено' : 'Получено';

    final iconColor = item.isSent ? colorScheme.primary : colorScheme.tertiary;

    final time =
        '${item.timestamp.hour.toString().padLeft(2, '0')}'
        ':${item.timestamp.minute.toString().padLeft(2, '0')}';

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (item.isFile && item.filePath != null) {
            open_file.OpenFile.open(item.filePath!);
          } else if (!item.isFile) {
            Clipboard.setData(ClipboardData(text: item.content));
            Toaster.info(title: "Текст скопирован в буфер обмена");
          }
        },
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
                    Text(
                      '$directionLabel • $time',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isFile || item.filePath != null)
                Icon(
                  item.isFile ? Icons.folder_open : Icons.copy,
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
    final result = await FilePicker.platform.pickFiles(
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
    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(12),
        title: const Text('Отправить текст'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          minLines: 1,
          autofocus: true,
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
            onPressed: () => Navigator.pop(context, controller.text),
            label: 'Отправить',
            type: .filled,
          ),
        ],
      ),
    );

    // Сохраняем текст до dispose, т.к. после него controller.text недоступен.
    final trimmed = text?.trim();
    controller.dispose();

    if (trimmed != null && trimmed.isNotEmpty && mounted) {
      await ref.read(transferProvider.notifier).sendText(trimmed);
    }
  }

 
}
