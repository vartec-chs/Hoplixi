import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';

enum VaultDBCloseSyncPhase {
  idle,
  checking,
  waitingForDecision,
  syncing,
  completed,
  skipped,
  failed,
}

enum VaultDBCloseSyncOutcomeType {
  noLogicalChanges,
  noBinding,
  staleTokenBinding,
  offlineAutoUpload,
  skippedByUser,
  uploaded,
  alreadySynced,
  manualResolutionRequired,
}

class VaultDBCloseSyncOutcome {
  const VaultDBCloseSyncOutcome(this.type, {this.resultType});

  final VaultDBCloseSyncOutcomeType type;
  final SnapshotSyncResultType? resultType;

  bool get completedUpload => type == VaultDBCloseSyncOutcomeType.uploaded;

  bool get clearsTracking =>
      type == VaultDBCloseSyncOutcomeType.uploaded ||
      type == VaultDBCloseSyncOutcomeType.alreadySynced;
}

class VaultDBCloseSyncState {
  const VaultDBCloseSyncState({
    this.phase = VaultDBCloseSyncPhase.idle,
    this.status,
    this.outcome,
    this.error,
  });

  final VaultDBCloseSyncPhase phase;
  final StoreSyncStatus? status;
  final VaultDBCloseSyncOutcome? outcome;
  final AppError? error;

  bool get isActive =>
      phase == VaultDBCloseSyncPhase.checking ||
      phase == VaultDBCloseSyncPhase.waitingForDecision ||
      phase == VaultDBCloseSyncPhase.syncing ||
      phase == VaultDBCloseSyncPhase.completed;

  VaultDBCloseSyncState copyWith({
    VaultDBCloseSyncPhase? phase,
    StoreSyncStatus? status,
    VaultDBCloseSyncOutcome? outcome,
    AppError? error,
    bool clearStatus = false,
    bool clearOutcome = false,
    bool clearError = false,
  }) {
    return VaultDBCloseSyncState(
      phase: phase ?? this.phase,
      status: clearStatus ? null : status ?? this.status,
      outcome: clearOutcome ? null : outcome ?? this.outcome,
      error: clearError ? null : error ?? this.error,
    );
  }
}
