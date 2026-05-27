import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/close_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_cloud_lock_provider.dart';
import 'package:hoplixi/vault_db/models/db_state.dart';
import 'package:hoplixi/vault_db/providers/vault_ui_state_provider.dart';

import '../../../features/cloud_sync/snapshot_sync/providers/close_sync_tracking_provider.dart';

/// Реактивный Эффект Облачной Синхронизации и Блокировок.
/// Слушает переходы презентационного стейта и запускает эффекты ровно один раз за переход.
final vaultCloseSyncEffectProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<DatabaseState>>(vaultDBManagerStateProvider, (
    previous,
    next,
  ) async {
    final prevVal = previous?.value;
    final nextVal = next.value;
    if (nextVal == null) return;

    // 1. Обнаружен переход в состояние закрытия (open -> closing)
    if (prevVal != null &&
        prevVal.status == DatabaseStatus.open &&
        nextVal.status == DatabaseStatus.closing) {
      final storeInfo = prevVal.info;
      final storePath = prevVal.path;
      if (storeInfo == null || storePath == null) return;

      logInfo(
        'Detecting close status, preparing close sync...',
        tag: 'VaultCloseSyncEffect',
      );
      ref
          .read(vaultDBCloseSyncProvider.notifier)
          .markCurrentStoreUploadRequiredIfLocalNewer(
            storeUuid: storeInfo.id,
            storePath: storePath,
          );
    }

    // 2. Обнаружено успешное закрытие или блокировка (closing -> closed / locked)
    if (prevVal != null &&
        prevVal.status == DatabaseStatus.closing &&
        (nextVal.status == DatabaseStatus.closed ||
            nextVal.status == DatabaseStatus.locked)) {
      final storeInfo = prevVal.info;
      final storePath = prevVal.path;
      if (storeInfo == null || storePath == null) return;

      final shouldSync = ref
          .read(closeSyncTrackingProvider)
          .hasLogicalChanges(storeInfo.modifiedAt);
      if (shouldSync) {
        logInfo(
          'Uploading database snapshot after close...',
          tag: 'VaultCloseSyncEffect',
        );
        final syncResult = await ref
            .read(vaultDBCloseSyncProvider.notifier)
            .uploadSnapshotAfterClose(
              storeInfo: storeInfo,
              currentStorePath: storePath,
            );

        if (syncResult.isError()) {
          final error = syncResult.exceptionOrNull()!;
          logError(
            'Snapshot sync after close failed: ${error.message}',
            tag: 'VaultCloseSyncEffect',
          );
        }
      }

      // Освобождаем облачную блокировку и сбрасываем состояние трекинга
      final releaseResult = await ref
          .read(currentStoreCloudLockProvider.notifier)
          .releaseCurrentLock();
      if (releaseResult.isError()) {
        logError(
          'Failed to release cloud store lock: ${releaseResult.exceptionOrNull()!.message}',
          tag: 'VaultCloseSyncEffect',
        );
      }

      ref.read(closeSyncTrackingProvider.notifier).closeSession();
      ref.read(vaultDBCloseSyncProvider.notifier).clearPublishedStatus();
      logInfo(
        'Close sync process and lock release finalized',
        tag: 'VaultCloseSyncEffect',
      );
    }
  });
});
