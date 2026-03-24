import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_service.dart';

Future<SnapshotConflictResolution?> showCloudSyncConflictDialog(
  BuildContext context, {
  required SnapshotSyncConflict conflict,
}) {
  return showDialog<SnapshotConflictResolution>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Конфликт синхронизации'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Автоматический merge отключён. Выберите, какую snapshot-версию считать основной.',
            ),
            const SizedBox(height: 16),
            Text(
              'Local: rev ${conflict.localManifest.revision}, snapshot ${conflict.localManifest.snapshotId}, updated ${conflict.localManifest.updatedAt.toUtc().toIso8601String()}',
            ),
            const SizedBox(height: 8),
            Text(
              'Remote: rev ${conflict.remoteManifest.revision}, snapshot ${conflict.remoteManifest.snapshotId}, updated ${conflict.remoteManifest.updatedAt.toUtc().toIso8601String()}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(SnapshotConflictResolution.downloadRemote),
            child: const Text('Download remote'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(SnapshotConflictResolution.uploadLocal),
            child: const Text('Upload local'),
          ),
        ],
      );
    },
  );
}
