import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';

enum CloudSyncRemoteChangeAction {
  later,
  downloadRemote,
  backupAndDownloadRemote,
  uploadLocal,
}

Future<CloudSyncRemoteChangeAction?> showCloudSyncRemoteChangeDialog(
  BuildContext context, {
  required StoreSyncStatus status,
}) {
  final localManifest = status.localManifest;
  final remoteManifest = status.remoteManifest;
  final isConflict = status.compareResult == StoreVersionCompareResult.conflict;

  return showDialog<CloudSyncRemoteChangeAction>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          isConflict
              ? 'Обнаружен конфликт snapshot-синхронизации'
              : 'В облаке доступна более новая snapshot-версия',
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConflict
                      ? 'Локальная и удалённая версии разошлись. Автоматический merge отключён, нужно вручную выбрать основную snapshot-версию.'
                      : 'Для текущего хранилища найдена более новая удалённая snapshot-версия. Перед загрузкой можно создать локальный backup.',
                ),
                const SizedBox(height: 16),
                Text('Хранилище: ${status.storeName ?? '-'}'),
                const SizedBox(height: 12),
                Text(
                  'Local: rev ${localManifest?.revision ?? '-'}, snapshot ${localManifest?.snapshotId ?? '-'}, updated ${localManifest?.updatedAt.toUtc().toIso8601String() ?? '-'}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Remote: rev ${remoteManifest?.revision ?? '-'}, snapshot ${remoteManifest?.snapshotId ?? '-'}, updated ${remoteManifest?.updatedAt.toUtc().toIso8601String() ?? '-'}',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(CloudSyncRemoteChangeAction.later),
            child: const Text('Позже'),
          ),
          if (isConflict)
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).pop(CloudSyncRemoteChangeAction.uploadLocal),
              child: const Text('Загрузить локальную'),
            ),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(CloudSyncRemoteChangeAction.downloadRemote),
            child: const Text('Скачать удалённую'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(CloudSyncRemoteChangeAction.backupAndDownloadRemote),
            child: const Text('Backup и скачать'),
          ),
        ],
      );
    },
  );
}
