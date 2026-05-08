import 'package:freezed_annotation/freezed_annotation.dart';

part 'cloud_store_lock.freezed.dart';
part 'cloud_store_lock.g.dart';

@freezed
sealed class CloudStoreLockDto with _$CloudStoreLockDto {
  const factory CloudStoreLockDto({
    required String storeUuid,
    required String deviceId,
    required String deviceName,
    required String appInstanceId,
    required String createdAt,
    required String updatedAt,
    required String lockId,
    required String appVersion,
    required String platform,
  }) = _CloudStoreLockDto;

  factory CloudStoreLockDto.fromJson(Map<String, dynamic> json) =>
      _$CloudStoreLockDtoFromJson(json);
}

enum CloudStoreLockAcquireStatus {
  syncDisabled,
  acquired,
  alreadyOwned,
  lockedByAnotherDevice,
  staleReplaced,
}

class CloudStoreLockAcquireResult {
  const CloudStoreLockAcquireResult({
    required this.status,
    this.currentLock,
    this.conflictingLock,
  });

  final CloudStoreLockAcquireStatus status;
  final CloudStoreLockDto? currentLock;
  final CloudStoreLockDto? conflictingLock;

  bool get ownsLock =>
      status == CloudStoreLockAcquireStatus.acquired ||
      status == CloudStoreLockAcquireStatus.alreadyOwned ||
      status == CloudStoreLockAcquireStatus.staleReplaced;

  bool get isLockedByAnotherDevice =>
      status == CloudStoreLockAcquireStatus.lockedByAnotherDevice;
}

abstract interface class CloudStoreLockRemoteStore {
  Future<CloudStoreLockDto?> readStoreLockFile(
    String tokenId, {
    required String storeUuid,
  });

  Future<void> writeStoreLockFile(
    String tokenId, {
    required String storeUuid,
    required CloudStoreLockDto lock,
  });

  Future<void> deleteStoreLockFile(String tokenId, {required String storeUuid});
}

enum CloudStoreLockPhase {
  idle,
  checking,
  available,
  lockedByAnotherDevice,
  riskAccepted,
  releasing,
  disabled,
  error,
}

class CloudStoreLockState {
  const CloudStoreLockState({
    required this.phase,
    this.storeUuid,
    this.storePath,
    this.storeName,
    this.ownedLock,
    this.conflictingLock,
    this.error,
  });

  const CloudStoreLockState.idle() : this(phase: CloudStoreLockPhase.idle);

  final CloudStoreLockPhase phase;
  final String? storeUuid;
  final String? storePath;
  final String? storeName;
  final CloudStoreLockDto? ownedLock;
  final CloudStoreLockDto? conflictingLock;
  final Object? error;

  bool get shouldBlockUi =>
      phase == CloudStoreLockPhase.checking ||
      phase == CloudStoreLockPhase.releasing ||
      phase == CloudStoreLockPhase.lockedByAnotherDevice ||
      phase == CloudStoreLockPhase.error;

  CloudStoreLockState copyWith({
    CloudStoreLockPhase? phase,
    String? storeUuid,
    String? storePath,
    String? storeName,
    CloudStoreLockDto? ownedLock,
    bool clearOwnedLock = false,
    CloudStoreLockDto? conflictingLock,
    bool clearConflictingLock = false,
    Object? error,
    bool clearError = false,
  }) {
    return CloudStoreLockState(
      phase: phase ?? this.phase,
      storeUuid: storeUuid ?? this.storeUuid,
      storePath: storePath ?? this.storePath,
      storeName: storeName ?? this.storeName,
      ownedLock: clearOwnedLock ? null : (ownedLock ?? this.ownedLock),
      conflictingLock: clearConflictingLock
          ? null
          : (conflictingLock ?? this.conflictingLock),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
