import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/local_send/models/history_item.dart';
import 'package:hoplixi/features/local_send/providers/persisted_history_provider.dart';
import 'package:hoplixi/features/local_send/widgets/import_store_archive_dialog.dart';
import 'package:hoplixi/main_store/services/archive_service.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:open_file/open_file.dart' as open_file;

class LocalSendHistoryScreen extends ConsumerWidget {
  const LocalSendHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(persistedHistoryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('История обменов'),
        actions: [
          historyAsync.maybeWhen(
            data: (items) => items.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Очистить историю',
                    onPressed: () => _confirmClear(context, ref),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  'Не удалось загрузить историю',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                SmoothButton(
                  label: 'Повторить',
                  onPressed: () =>
                      ref.read(persistedHistoryProvider.notifier).reload(),
                  type: SmoothButtonType.tonal,
                ),
              ],
            ),
          ),
          data: (items) => items.isEmpty
              ? _buildEmpty(colorScheme, textTheme)
              : _buildList(context, ref, items, colorScheme, textTheme),
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'История пуста',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Здесь будут отображаться\nотправленные и полученные данные',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<HistoryItem> items,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Показываем в порядке от новых к старым.
    final reversed = items.reversed.toList();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: reversed.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = reversed[index];
        final originalIndex = items.length - 1 - index;
        return _buildHistoryTile(
          context,
          ref,
          item,
          originalIndex,
          colorScheme,
          textTheme,
        );
      },
    );
  }

  Widget _buildHistoryTile(
    BuildContext context,
    WidgetRef ref,
    HistoryItem item,
    int originalIndex,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final icon = item.isFile
        ? (item.isSent ? Icons.upload_file : Icons.download)
        : (item.isSent ? Icons.send : Icons.message);

    final iconColor = item.isSent ? colorScheme.primary : colorScheme.tertiary;

    final directionLabel = item.isSent ? 'Отправлено' : 'Получено';
    final deviceName = item.deviceName?.trim();
    final hasDeviceName = deviceName != null && deviceName.isNotEmpty;

    final timestamp = item.timestamp;
    final now = DateTime.now();
    final isToday =
        timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    final dateStr = isToday
        ? timeStr
        : '${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year} $timeStr';

    return Dismissible(
      key: ValueKey('${item.timestamp.microsecondsSinceEpoch}_$originalIndex'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
      ),
      onDismissed: (_) {
        ref.read(persistedHistoryProvider.notifier).removeAt(originalIndex);
        Toaster.info(title: 'Запись удалена');
      },
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleTap(context, ref, item),
          onLongPress: () => _showItemMenu(context, ref, item, originalIndex),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
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
                      if (hasDeviceName) ...[
                        const SizedBox(height: 2),
                        Text(
                          deviceName,
                          style: textTheme.bodySmall?.copyWith(
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        '$directionLabel • $dateStr',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!item.isFile || item.filePath != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    item.isFile ? Icons.folder_open_outlined : Icons.copy,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    HistoryItem item,
  ) async {
    if (item.isFile && item.filePath != null) {
      if (!item.isSent && ArchiveService.isStoreArchiveFile(item.filePath!)) {
        await showStoreArchiveImportDialog(
          context,
          ref,
          archivePath: item.filePath!,
        );
        return;
      }

      await open_file.OpenFile.open(item.filePath!);
    } else if (!item.isFile) {
      await Clipboard.setData(ClipboardData(text: item.content));
      Toaster.info(title: 'Текст скопирован в буфер обмена');
    }
  }

  void _showItemMenu(
    BuildContext context,
    WidgetRef ref,
    HistoryItem item,
    int originalIndex,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!item.isFile)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Копировать текст'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Clipboard.setData(ClipboardData(text: item.content));
                  Toaster.info(title: 'Текст скопирован в буфер обмена');
                },
              ),
            if (item.isFile && item.filePath != null) ...[
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: const Text('Открыть файл'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  open_file.OpenFile.open(item.filePath!);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Копировать путь'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Clipboard.setData(ClipboardData(text: item.filePath!));
                  Toaster.info(title: 'Путь скопирован в буфер обмена');
                },
              ),
            ],
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Удалить запись',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(persistedHistoryProvider.notifier)
                    .removeAt(originalIndex);
                Toaster.info(title: 'Запись удалена');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить историю'),
        content: const Text(
          'Все записи истории обменов будут удалены. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(persistedHistoryProvider.notifier).clearAll();
      Toaster.success(title: 'История очищена');
    }
  }
}
