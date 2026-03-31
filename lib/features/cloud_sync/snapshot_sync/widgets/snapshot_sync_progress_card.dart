import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';

class SnapshotSyncProgressCard extends StatelessWidget {
  const SnapshotSyncProgressCard({required this.progress, super.key});

  final SnapshotSyncProgress progress;

  @override
  Widget build(BuildContext context) {
    final transfer = progress.transferProgress;
    final fraction = transfer?.fraction;
    final directionLabel = switch (transfer?.direction) {
      SnapshotSyncTransferDirection.upload => 'Загружено',
      SnapshotSyncTransferDirection.download => 'Скачано',
      null => null,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              progress.title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('Шаг ${progress.stepIndex} из ${progress.totalSteps}'),
            const SizedBox(height: 8),
            Text(progress.description),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: fraction),
            if (transfer != null) ...[
              const SizedBox(height: 12),
              if (transfer.hasFileProgress)
                Text(
                  '$directionLabel ${transfer.completedFiles} из ${transfer.totalFiles} файлов',
                ),
              if (transfer.totalBytes != null)
                Text(
                  '${formatSnapshotSyncBytes(transfer.transferredBytes)} из ${formatSnapshotSyncBytes(transfer.totalBytes!)}',
                ),
              if ((transfer.currentFileName ?? '').trim().isNotEmpty)
                Text('Текущий файл: ${transfer.currentFileName}'),
            ],
          ],
        ),
      ),
    );
  }
}

class SnapshotSyncPendingApplyCard extends StatelessWidget {
  const SnapshotSyncPendingApplyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Удалённый snapshot готов',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Новая версия уже записана локально. Разблокируйте хранилище, чтобы продолжить работу с обновлёнными данными.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String formatSnapshotSyncBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }
  const suffixes = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var index = 0;
  while (value >= 1024 && index < suffixes.length - 1) {
    value /= 1024;
    index += 1;
  }
  final precision = value >= 10 || index == 0 ? 0 : 1;
  return '${value.toStringAsFixed(precision)} ${suffixes[index]}';
}
