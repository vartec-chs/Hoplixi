import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';

class CloudSyncProgressPanel extends StatelessWidget {
  final SnapshotSyncProgress? progress;

  const CloudSyncProgressPanel({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final transfer = progress!.transferProgress;
    final fraction = transfer?.fraction;
    final fileProgressText = transfer != null && transfer.hasFileProgress
        ? '${transfer.completedFiles} из ${transfer.totalFiles} файлов'
        : null;
    final bytesProgressText = transfer != null && transfer.totalBytes != null
        ? '${_formatBytes(transfer.transferredBytes)} из ${_formatBytes(transfer.totalBytes!)}'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progress!.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Шаг ${progress!.stepIndex} из ${progress!.totalSteps}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            progress!.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: fraction),
          if (fileProgressText != null) ...[
            const SizedBox(height: 10),
            Text(
              fileProgressText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (bytesProgressText != null) ...[
            const SizedBox(height: 4),
            Text(
              bytesProgressText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (transfer?.currentFileName != null &&
              transfer!.currentFileName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Текущий файл: ${transfer.currentFileName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    const units = ['Б', 'КБ', 'МБ', 'ГБ'];
    var value = bytes.toDouble();
    var unitIndex = 0;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    final precision = value >= 100 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(precision)} ${units[unitIndex]}';
  }
}
