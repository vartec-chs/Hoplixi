import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_service.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/main_store/models/db_state.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

final currentStoreSyncProvider =
    AsyncNotifierProvider<CurrentStoreSyncNotifier, StoreSyncStatus>(
      CurrentStoreSyncNotifier.new,
    );

class CurrentStoreSyncNotifier extends AsyncNotifier<StoreSyncStatus> {
  @override
  Future<StoreSyncStatus> build() async {
    final storeState = await ref.watch(mainStoreProvider.future);
    return _loadCurrentStatus(storeState, useWatch: true);
  }

  Future<void> loadStatus({bool rethrowOnError = false}) async {
    final previous = state.value;
    state = const AsyncLoading();
    try {
      final storeState = await ref.read(mainStoreProvider.future);
      final next = await _loadCurrentStatus(storeState, useWatch: false);
      state = AsyncData(next);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
      if (rethrowOnError) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }

  Future<void> connect(String tokenId) async {
    final current = await future;
    final storeUuid = current.storeUuid;
    if (storeUuid == null) {
      throw StateError('Store UUID is unavailable.');
    }

    final token = await _loadToken(tokenId);
    if (token == null) {
      throw StateError('OAuth token was not found.');
    }

    final bindingService = ref.read(storeSyncBindingServiceProvider);
    final syncService = ref.read(snapshotSyncServiceProvider);
    await bindingService.saveBinding(
      storeUuid: storeUuid,
      tokenId: token.id,
      provider: token.provider,
    );
    final savedBinding = await bindingService.getByStoreUuid(storeUuid);
    try {
      await syncService.initializeRemoteLayout(
        tokenId: token.id,
        storeUuid: storeUuid,
      );
      await loadStatus(rethrowOnError: true);
    } catch (error, stackTrace) {
      if (_canKeepBindingAfterConnectProbeError(error) &&
          savedBinding != null) {
        state = AsyncData(
          current.copyWith(
            binding: savedBinding,
            token: token,
            clearRemoteManifest: true,
            clearPendingConflict: true,
            compareResult: StoreVersionCompareResult.remoteMissing,
            lastResultType: SnapshotSyncResultType.idle,
          ),
        );
        return;
      }
      if (current.binding != null) {
        await bindingService.saveBinding(
          storeUuid: current.binding!.storeUuid,
          tokenId: current.binding!.tokenId,
          provider: current.binding!.provider,
        );
      } else {
        await bindingService.deleteBinding(storeUuid);
      }
      state = AsyncData(current);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  bool _canKeepBindingAfterConnectProbeError(Object error) {
    return switch (error) {
      _ when error is CloudStorageException =>
        error.type == CloudStorageExceptionType.network ||
            error.type == CloudStorageExceptionType.timeout,
      _ => false,
    };
  }

  Future<void> disconnect() async {
    final current = await future;
    final storeUuid = current.storeUuid;
    if (storeUuid == null) {
      return;
    }

    await ref.read(storeSyncBindingServiceProvider).deleteBinding(storeUuid);
    state = AsyncData(
      current.copyWith(
        clearBinding: true,
        clearToken: true,
        clearRemoteManifest: true,
        clearPendingConflict: true,
        compareResult: StoreVersionCompareResult.remoteMissing,
      ),
    );
    await loadStatus();
  }

  Future<void> syncNow() async {
    final current = await future;
    final binding = current.binding;
    final token = current.token;
    final storePath = current.storePath;
    if (binding == null || token == null || storePath == null) {
      throw StateError('Cloud sync is not connected.');
    }

    final manager = await ref.read(mainStoreManagerProvider.future);
    if (manager == null) {
      throw StateError('Store manager is unavailable.');
    }
    final storeInfoResult = await manager.getStoreInfo();
    final storeInfo = storeInfoResult.fold(
      (info) => info,
      (error) => throw error,
    );
    final syncService = ref.read(snapshotSyncServiceProvider);

    if (current.compareResult == StoreVersionCompareResult.conflict) {
      state = AsyncData(
        current.copyWith(
          pendingConflict:
              current.pendingConflict ??
              (current.remoteManifest == null || current.localManifest == null
                  ? null
                  : SnapshotSyncConflict(
                      localManifest: current.localManifest!,
                      remoteManifest: current.remoteManifest!,
                    )),
          lastResultType: SnapshotSyncResultType.conflict,
        ),
      );
      return;
    }

    if (current.compareResult == StoreVersionCompareResult.remoteNewer) {
      final downloadInProgressState = current.copyWith(
        isStoreOpen: false,
        storePath: storePath,
        storeUuid: binding.storeUuid,
        binding: binding,
        token: token,
        clearPendingConflict: true,
        requiresUnlockToApply: false,
        isApplyingRemoteUpdate: true,
      );
      state = AsyncData(downloadInProgressState);
      try {
        await ref
            .read(mainStoreProvider.notifier)
            .lockStore(skipSnapshotSync: true);
        final result = await syncService.resolveConflict(
          storePath: storePath,
          storeInfo: storeInfo,
          binding: binding,
          token: token,
          resolution: SnapshotConflictResolution.downloadRemote,
          lockBeforeDownload: true,
        );
        state = AsyncData(
          StoreSyncStatus(
            isStoreOpen: false,
            storePath: storePath,
            storeUuid: binding.storeUuid,
            storeName: current.storeName,
            binding: binding,
            token: token,
            localManifest: result.localManifest,
            remoteManifest: result.remoteManifest,
            compareResult: StoreVersionCompareResult.same,
            lastResultType: result.type,
            requiresUnlockToApply: true,
            isApplyingRemoteUpdate: false,
          ),
        );
        return;
      } catch (error, stackTrace) {
        state = AsyncData(
          downloadInProgressState.copyWith(isApplyingRemoteUpdate: false),
        );
        Error.throwWithStackTrace(error, stackTrace);
      }
    }

    state = const AsyncLoading();

    final result = await syncService.sync(
      storePath: storePath,
      storeInfo: storeInfo,
      binding: binding,
      token: token,
    );

    if (result.type == SnapshotSyncResultType.conflict) {
      state = AsyncData(
        current.copyWith(
          localManifest: result.localManifest,
          remoteManifest: result.remoteManifest,
          pendingConflict: result.conflict,
          compareResult: StoreVersionCompareResult.conflict,
          lastResultType: SnapshotSyncResultType.conflict,
        ),
      );
      return;
    }

    await loadStatus();
    final refreshed = await future;
    state = AsyncData(refreshed.copyWith(lastResultType: result.type));
  }

  Future<void> resolveConflictWithUpload() async {
    await _resolveConflict(SnapshotConflictResolution.uploadLocal);
  }

  Future<void> resolveConflictWithDownload() async {
    await _resolveConflict(SnapshotConflictResolution.downloadRemote);
  }

  Future<void> _resolveConflict(SnapshotConflictResolution resolution) async {
    final current = await future;
    final binding = current.binding;
    final token = current.token;
    final storePath = current.storePath;
    if (binding == null || token == null || storePath == null) {
      throw StateError('Cloud sync is not connected.');
    }

    final manager = await ref.read(mainStoreManagerProvider.future);
    if (manager == null) {
      throw StateError('Store manager is unavailable.');
    }
    final storeInfoResult = await manager.getStoreInfo();
    final storeInfo = storeInfoResult.fold(
      (info) => info,
      (error) => throw error,
    );
    final syncService = ref.read(snapshotSyncServiceProvider);

    var requiresUnlock = false;
    if (resolution == SnapshotConflictResolution.downloadRemote) {
      final downloadInProgressState = current.copyWith(
        isStoreOpen: false,
        storePath: storePath,
        storeUuid: binding.storeUuid,
        binding: binding,
        token: token,
        clearPendingConflict: true,
        requiresUnlockToApply: false,
        isApplyingRemoteUpdate: true,
      );
      state = AsyncData(downloadInProgressState);
      try {
        await ref
            .read(mainStoreProvider.notifier)
            .lockStore(skipSnapshotSync: true);
      } catch (error, stackTrace) {
        state = AsyncData(
          downloadInProgressState.copyWith(isApplyingRemoteUpdate: false),
        );
        Error.throwWithStackTrace(error, stackTrace);
      }
      requiresUnlock = true;
    } else {
      state = const AsyncLoading();
    }

    final result = requiresUnlock
        ? await (() async {
            try {
              return await syncService.resolveConflict(
                storePath: storePath,
                storeInfo: storeInfo,
                binding: binding,
                token: token,
                resolution: resolution,
                lockBeforeDownload: true,
              );
            } catch (error, stackTrace) {
              state = AsyncData(
                current.copyWith(
                  isStoreOpen: false,
                  storePath: storePath,
                  storeUuid: binding.storeUuid,
                  binding: binding,
                  token: token,
                  clearPendingConflict: true,
                  requiresUnlockToApply: false,
                  isApplyingRemoteUpdate: false,
                ),
              );
              Error.throwWithStackTrace(error, stackTrace);
            }
          })()
        : await syncService.resolveConflict(
            storePath: storePath,
            storeInfo: storeInfo,
            binding: binding,
            token: token,
            resolution: resolution,
            lockBeforeDownload: false,
          );

    if (requiresUnlock) {
      state = AsyncData(
        StoreSyncStatus(
          isStoreOpen: false,
          storePath: storePath,
          storeUuid: binding.storeUuid,
          storeName: current.storeName,
          binding: binding,
          token: token,
          localManifest: result.localManifest,
          remoteManifest: result.remoteManifest,
          compareResult: StoreVersionCompareResult.same,
          lastResultType: result.type,
          requiresUnlockToApply: true,
          isApplyingRemoteUpdate: false,
        ),
      );
      return;
    }

    await loadStatus();
    final refreshed = await future;
    state = AsyncData(
      refreshed.copyWith(
        lastResultType: result.type,
        clearPendingConflict: true,
      ),
    );
  }

  Future<AuthTokenEntry?> _loadToken(String tokenId) {
    return ref.read(authTokensProvider.notifier).getTokenById(tokenId);
  }

  Future<StoreSyncStatus> _loadCurrentStatus(
    DatabaseState storeState, {
    required bool useWatch,
  }) async {
    if (!storeState.isOpen) {
      return StoreSyncStatus(
        isStoreOpen: false,
        storePath: storeState.path,
        storeName: storeState.name,
      );
    }

    final manager = useWatch
        ? await ref.watch(mainStoreManagerProvider.future)
        : await ref.read(mainStoreManagerProvider.future);
    if (manager == null) {
      return const StoreSyncStatus(isStoreOpen: false);
    }

    final storeInfoResult = await manager.getStoreInfo();
    final storeInfo = storeInfoResult.fold(
      (info) => info,
      (error) => throw error,
    );

    final bindingService = ref.read(storeSyncBindingServiceProvider);
    var binding = await bindingService.getByStoreUuid(storeInfo.id);
    final token = binding == null ? null : await _loadToken(binding.tokenId);
    if (binding != null && token == null) {
      await bindingService.deleteBinding(storeInfo.id);
      binding = null;
    }

    final syncService = ref.read(snapshotSyncServiceProvider);
    final skipRemoteCheck =
        useWatch &&
        binding != null &&
        token != null &&
        !await _hasInternetAccess();
    return syncService.loadStatus(
      storePath: manager.currentStorePath!,
      storeInfo: storeInfo,
      binding: binding,
      token: token,
      skipRemoteManifestCheck: skipRemoteCheck,
      remoteCheckSkippedOffline: skipRemoteCheck,
    );
  }

  Future<bool> _hasInternetAccess() async {
    try {
      return await ref.read(internetConnectionProvider).hasInternetAccess;
    } catch (_) {
      return false;
    }
  }
}
