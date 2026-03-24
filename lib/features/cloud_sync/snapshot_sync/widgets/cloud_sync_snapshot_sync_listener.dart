import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/widgets/cloud_sync_remote_change_dialog.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

class CloudSyncSnapshotSyncListener extends ConsumerStatefulWidget {
  const CloudSyncSnapshotSyncListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CloudSyncSnapshotSyncListener> createState() =>
      _CloudSyncSnapshotSyncListenerState();
}

class _CloudSyncSnapshotSyncListenerState
    extends ConsumerState<CloudSyncSnapshotSyncListener> {
  static const String _logTag = 'CloudSyncSnapshotSyncListener';

  ProviderSubscription<AsyncValue<StoreSyncStatus>>? _subscription;
  String? _handledPromptKey;
  bool _isHandlingPrompt = false;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<AsyncValue<StoreSyncStatus>>(
      currentStoreSyncProvider,
      (previous, next) {
        next.whenData((status) {
          final promptKey = _buildPromptKey(status);
          if (promptKey == null) {
            _handledPromptKey = null;
            return;
          }

          if (_isHandlingPrompt || _handledPromptKey == promptKey) {
            return;
          }

          _handledPromptKey = promptKey;
          _isHandlingPrompt = true;

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await _handlePrompt(status);
            } finally {
              _isHandlingPrompt = false;
            }
          });
        });
      },
      fireImmediately: true,
    );
  }

  String? _buildPromptKey(StoreSyncStatus status) {
    if (!status.isStoreOpen || status.binding == null) {
      return null;
    }

    final compareResult = status.compareResult;
    final shouldPrompt =
        compareResult == StoreVersionCompareResult.remoteNewer ||
        compareResult == StoreVersionCompareResult.conflict;
    if (!shouldPrompt) {
      return null;
    }

    return [
      status.storeUuid ?? '',
      compareResult.name,
      status.localManifest?.revision.toString() ?? '',
      status.localManifest?.snapshotId ?? '',
      status.remoteManifest?.revision.toString() ?? '',
      status.remoteManifest?.snapshotId ?? '',
    ].join('|');
  }

  Future<void> _handlePrompt(StoreSyncStatus status) async {
    final dialogContext =
        navigatorKey.currentState?.overlay?.context ??
        navigatorKey.currentContext;
    if (dialogContext == null || !mounted) {
      logWarning(
        'Skipping snapshot sync prompt because no Navigator context is available.',
        tag: _logTag,
        data: <String, dynamic>{
          'storeUuid': status.storeUuid,
          'compareResult': status.compareResult.name,
        },
      );
      return;
    }

    final action = await showCloudSyncRemoteChangeDialog(
      dialogContext,
      status: status,
    );
    if (!mounted ||
        action == null ||
        action == CloudSyncRemoteChangeAction.later) {
      return;
    }

    try {
      switch (action) {
        case CloudSyncRemoteChangeAction.later:
          return;
        case CloudSyncRemoteChangeAction.uploadLocal:
          await ref
              .read(currentStoreSyncProvider.notifier)
              .resolveConflictWithUpload();
          Toaster.success(
            title: 'Cloud Sync',
            description: 'Локальная snapshot-версия загружена в облако.',
          );
          break;
        case CloudSyncRemoteChangeAction.downloadRemote:
          await ref
              .read(currentStoreSyncProvider.notifier)
              .resolveConflictWithDownload();
          Toaster.success(
            title: 'Cloud Sync',
            description:
                'Удалённая snapshot-версия загружена. Разблокируйте хранилище, чтобы продолжить работу.',
          );
          break;
        case CloudSyncRemoteChangeAction.backupAndDownloadRemote:
          final backup = await ref
              .read(mainStoreProvider.notifier)
              .createBackup(periodic: false);
          if (backup == null) {
            Toaster.error(
              title: 'Cloud Sync',
              description:
                  'Не удалось создать backup перед загрузкой удалённой версии.',
            );
            return;
          }
          await ref
              .read(currentStoreSyncProvider.notifier)
              .resolveConflictWithDownload();
          Toaster.success(
            title: 'Cloud Sync',
            description:
                'Backup создан, удалённая snapshot-версия загружена. Разблокируйте хранилище, чтобы продолжить работу.',
          );
          break;
      }
    } catch (error, stackTrace) {
      logError(
        'Snapshot sync prompt action failed: $error',
        stackTrace: stackTrace,
        tag: _logTag,
        data: <String, dynamic>{
          'storeUuid': status.storeUuid,
          'compareResult': status.compareResult.name,
          'action': action.name,
        },
      );
      Toaster.error(title: 'Cloud Sync', description: error.toString());
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
