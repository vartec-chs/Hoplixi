import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_store_lock.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/cloud_store_lock_service.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:result_dart/result_dart.dart';

final currentStoreCloudLockProvider =
    AsyncNotifierProvider<CurrentStoreCloudLockNotifier, CloudStoreLockState>(
      CurrentStoreCloudLockNotifier.new,
    );

final cloudStoreLockSessionProvider = Provider<CloudStoreLockSession>((ref) {
  return CloudStoreLockSession();
});

class CloudStoreLockSession {
  CloudStoreLockDto? _ownedLock;
  String? _ownedLockTokenId;

  void setOwnedLock({required String tokenId, required CloudStoreLockDto lock}) {
    _ownedLock = lock;
    _ownedLockTokenId = tokenId;
  }

  AsyncResultDart<Unit, AppError> releaseCurrentLock(
    CloudStoreLockService service,
  ) async {
    final lock = _ownedLock;
    final tokenId = _ownedLockTokenId;
    if (lock == null || tokenId == null) {
      return const Success(unit);
    }

    final result = await service.releaseLock(tokenId: tokenId, lock: lock);
    if (result.isSuccess()) {
      _ownedLock = null;
      _ownedLockTokenId = null;
    }
    return result;
  }
}

class CurrentStoreCloudLockNotifier extends AsyncNotifier<CloudStoreLockState> {
  static const String _logTag = 'CurrentStoreCloudLockProvider';

  @override
  Future<CloudStoreLockState> build() async {
    final storeState = await ref.watch(mainStoreProvider.future);
    if (!storeState.isOpen) {
      return const CloudStoreLockState.idle();
    }

    state = AsyncData(
      CloudStoreLockState(
        phase: CloudStoreLockPhase.checking,
        storeUuid: storeState.info?.id,
        storePath: storeState.path,
        storeName: storeState.name,
      ),
    );

    try {
      final storeInfo = storeState.info;
      if (storeInfo == null) {
        throw const AppError.feature(
          feature: 'cloud_sync',
          code: 'store_info_missing',
          message: 'Данные открытого хранилища недоступны',
        );
      }
      final binding = await ref
          .read(storeSyncBindingServiceProvider)
          .getByStoreUuid(storeInfo.id);
      if (binding == null) {
        return CloudStoreLockState(
          phase: CloudStoreLockPhase.disabled,
          storeUuid: storeInfo.id,
          storePath: storeState.path,
          storeName: storeInfo.name,
        );
      }

      final token = await ref
          .read(authTokensProvider.notifier)
          .getTokenById(binding.tokenId);
      if (token == null) {
        return CloudStoreLockState(
          phase: CloudStoreLockPhase.disabled,
          storeUuid: storeInfo.id,
          storePath: storeState.path,
          storeName: storeInfo.name,
        );
      }

      final result = await ref
          .read(cloudStoreLockServiceProvider)
          .acquireLock(
            tokenId: token.id,
            storeUuid: storeInfo.id,
            syncEnabled: true,
          );

      return result.fold(
        (acquireResult) {
          if (acquireResult.ownsLock) {
            final currentLock = acquireResult.currentLock;
            if (currentLock != null) {
              ref
                  .read(cloudStoreLockSessionProvider)
                  .setOwnedLock(tokenId: token.id, lock: currentLock);
            }
            return CloudStoreLockState(
              phase: CloudStoreLockPhase.available,
              storeUuid: storeInfo.id,
              storePath: storeState.path,
              storeName: storeInfo.name,
              ownedLock: currentLock,
            );
          }

          if (acquireResult.isLockedByAnotherDevice) {
            return CloudStoreLockState(
              phase: CloudStoreLockPhase.lockedByAnotherDevice,
              storeUuid: storeInfo.id,
              storePath: storeState.path,
              storeName: storeInfo.name,
              conflictingLock: acquireResult.conflictingLock,
            );
          }

          return CloudStoreLockState(
            phase: CloudStoreLockPhase.disabled,
            storeUuid: storeInfo.id,
            storePath: storeState.path,
            storeName: storeInfo.name,
          );
        },
        (error) {
          return CloudStoreLockState(
            phase: CloudStoreLockPhase.error,
            storeUuid: storeInfo.id,
            storePath: storeState.path,
            storeName: storeInfo.name,
            error: error,
          );
        },
      );
    } catch (error, stackTrace) {
      logError(
        'Cloud store lock check failed: $error',
        stackTrace: stackTrace,
        tag: _logTag,
        data: <String, dynamic>{
          'storeUuid': storeState.info?.id,
          'storePath': storeState.path,
          'errorType': error.runtimeType.toString(),
        },
      );
      return CloudStoreLockState(
        phase: CloudStoreLockPhase.error,
        storeUuid: storeState.info?.id,
        storePath: storeState.path,
        storeName: storeState.name,
        error: error,
      );
    }
  }

  void acceptRiskForCurrentStore() {
    final current = state.value;
    if (current == null ||
        current.phase != CloudStoreLockPhase.lockedByAnotherDevice) {
      return;
    }
    logWarning(
      'User accepted opening cloud-synced store while another device lock exists.',
      tag: _logTag,
      data: <String, dynamic>{
        'storeUuid': current.storeUuid,
        'conflictingDeviceId': current.conflictingLock?.deviceId,
        'conflictingDeviceName': current.conflictingLock?.deviceName,
        'conflictingUpdatedAt': current.conflictingLock?.updatedAt,
      },
    );
    state = AsyncData(
      current.copyWith(phase: CloudStoreLockPhase.riskAccepted),
    );
  }

  void retry() {
    state = const AsyncLoading<CloudStoreLockState>();
    ref.invalidateSelf();
  }

  AsyncResultDart<Unit, AppError> releaseCurrentLock() async {
    final result = await ref
        .read(cloudStoreLockSessionProvider)
        .releaseCurrentLock(ref.read(cloudStoreLockServiceProvider));
    if (result.isSuccess()) {
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            phase: CloudStoreLockPhase.idle,
            clearOwnedLock: true,
          ),
        );
      }
    }
    return result;
  }
}
