import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/di_init.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_repository.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_service.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/store_sync_binding_service.dart';
import 'package:hoplixi/features/cloud_sync/storage/providers/cloud_storage_provider.dart';
import 'package:hoplixi/main_store/models/db_state.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

final storeSyncBindingServiceProvider = Provider<StoreSyncBindingService>((ref) {
  final service = StoreSyncBindingService(getIt<HiveBoxManager>());
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final snapshotSyncRepositoryProvider = Provider<SnapshotSyncRepository>((ref) {
  final storageRepository = ref.watch(cloudStorageRepositoryProvider);
  return SnapshotSyncRepository(storageRepository);
});

final snapshotSyncServiceProvider = Provider<SnapshotSyncService>((ref) {
  final repository = ref.watch(snapshotSyncRepositoryProvider);
  return SnapshotSyncService(repository: repository);
});

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

  Future<void> loadStatus() async {
    state = const AsyncLoading();
    final storeState = await ref.read(mainStoreProvider.future);
    state = await AsyncValue.guard(
      () => _loadCurrentStatus(storeState, useWatch: false),
    );
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
    await bindingService.saveBinding(
      storeUuid: storeUuid,
      tokenId: token.id,
      provider: token.provider,
    );
    await loadStatus();
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
    final storeInfo = storeInfoResult.fold((info) => info, (error) => throw error);
    final syncService = ref.read(snapshotSyncServiceProvider);

    state = const AsyncLoading();

    if (current.compareResult == StoreVersionCompareResult.conflict) {
      state = AsyncData(
        current.copyWith(
          pendingConflict: current.pendingConflict ??
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
      await ref.read(mainStoreProvider.notifier).lockStore();
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
        ),
      );
      return;
    }

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
    final storeInfo = storeInfoResult.fold((info) => info, (error) => throw error);
    final syncService = ref.read(snapshotSyncServiceProvider);

    state = const AsyncLoading();

    var requiresUnlock = false;
    if (resolution == SnapshotConflictResolution.downloadRemote) {
      await ref.read(mainStoreProvider.notifier).lockStore();
      requiresUnlock = true;
    }

    final result = await syncService.resolveConflict(
      storePath: storePath,
      storeInfo: storeInfo,
      binding: binding,
      token: token,
      resolution: resolution,
      lockBeforeDownload: requiresUnlock,
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
    final storeInfo = storeInfoResult.fold((info) => info, (error) => throw error);

    final bindingService = ref.read(storeSyncBindingServiceProvider);
    var binding = await bindingService.getByStoreUuid(storeInfo.id);
    final token = binding == null ? null : await _loadToken(binding.tokenId);
    if (binding != null && token == null) {
      await bindingService.deleteBinding(storeInfo.id);
      binding = null;
    }

    final syncService = ref.read(snapshotSyncServiceProvider);
    return syncService.loadStatus(
      storePath: manager.currentStorePath!,
      storeInfo: storeInfo,
      binding: binding,
      token: token,
    );
  }
}
