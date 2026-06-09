import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';

class RecentDatabaseCloudSyncState {
  const RecentDatabaseCloudSyncState({
    required this.isChecking,
    required this.progress,
  });

  const RecentDatabaseCloudSyncState.idle()
    : isChecking = false,
      progress = null;

  final bool isChecking;
  final SnapshotSyncProgress? progress;

  RecentDatabaseCloudSyncState copyWith({
    bool? isChecking,
    SnapshotSyncProgress? progress,
    bool clearProgress = false,
  }) {
    return RecentDatabaseCloudSyncState(
      isChecking: isChecking ?? this.isChecking,
      progress: clearProgress ? null : progress ?? this.progress,
    );
  }
}
