import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';

enum MainStoreCloseSyncPhase {
  idle,
  checking,
  waitingForDecision,
  syncing,
  completed,
  skipped,
  failed,
}

enum MainStoreCloseSyncOutcomeType {
  noLogicalChanges,
  noBinding,
  staleTokenBinding,
  offlineAutoUpload,
  skippedByUser,
  uploaded,
  alreadySynced,
  manualResolutionRequired,
}

class MainStoreCloseSyncOutcome {
  const MainStoreCloseSyncOutcome(this.type, {this.resultType});

  final MainStoreCloseSyncOutcomeType type;
  final SnapshotSyncResultType? resultType;

  bool get completedUpload => type == MainStoreCloseSyncOutcomeType.uploaded;

  bool get clearsTracking =>
      type == MainStoreCloseSyncOutcomeType.uploaded ||
      type == MainStoreCloseSyncOutcomeType.alreadySynced;
}

class MainStoreCloseSyncState {
  const MainStoreCloseSyncState({
    this.phase = MainStoreCloseSyncPhase.idle,
    this.status,
    this.outcome,
    this.error,
  });

  final MainStoreCloseSyncPhase phase;
  final StoreSyncStatus? status;
  final MainStoreCloseSyncOutcome? outcome;
  final AppError? error;

  bool get isActive =>
      phase == MainStoreCloseSyncPhase.checking ||
      phase == MainStoreCloseSyncPhase.waitingForDecision ||
      phase == MainStoreCloseSyncPhase.syncing;

  MainStoreCloseSyncState copyWith({
    MainStoreCloseSyncPhase? phase,
    StoreSyncStatus? status,
    MainStoreCloseSyncOutcome? outcome,
    AppError? error,
    bool clearStatus = false,
    bool clearOutcome = false,
    bool clearError = false,
  }) {
    return MainStoreCloseSyncState(
      phase: phase ?? this.phase,
      status: clearStatus ? null : status ?? this.status,
      outcome: clearOutcome ? null : outcome ?? this.outcome,
      error: clearError ? null : error ?? this.error,
    );
  }
}
