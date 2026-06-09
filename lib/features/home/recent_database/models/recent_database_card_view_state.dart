import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_store_lock.dart';
import 'package:hoplixi/vault_db/models/db_state.dart';
import 'package:hoplixi/vault_db/services/db_history_services/model/db_history_model.dart';
import 'package:hoplixi/vault_db/services/store_manifest_service/model/store_manifest.dart';

class RecentDatabaseCardViewState {
  const RecentDatabaseCardViewState({
    required this.isOpening,
    required this.isCloudLockChecking,
    required this.isCloudLockReleasing,
    required this.syncProvider,
  });

  final bool isOpening;
  final bool isCloudLockChecking;
  final bool isCloudLockReleasing;
  final CloudSyncProvider? syncProvider;

  static RecentDatabaseCardViewState from({
    required DatabaseEntry entry,
    required DatabaseState? dbState,
    required AsyncValue<CloudStoreLockState> lockState,
    required AsyncValue<StoreManifest?> manifestAsync,
  }) {
    final lockValue = lockState.value;
    final isCurrentStoreCard =
        dbState?.path == entry.path || lockValue?.storePath == entry.path;

    final lockPhase = lockValue?.phase;

    final isCloudLockChecking =
        isCurrentStoreCard &&
        ((lockState.isLoading && lockState.value == null) ||
            lockPhase == CloudStoreLockPhase.checking);

    final isCloudLockReleasing =
        isCurrentStoreCard &&
        (lockPhase == CloudStoreLockPhase.releasing ||
            (dbState?.isClosing ?? false));

    final syncProvider = manifestAsync.maybeWhen(
      data: (manifest) => manifest?.sync?.provider,
      orElse: () => null,
    );

    return RecentDatabaseCardViewState(
      isOpening: dbState?.isOpening ?? false,
      isCloudLockChecking: isCloudLockChecking,
      isCloudLockReleasing: isCloudLockReleasing,
      syncProvider: syncProvider,
    );
  }
}
