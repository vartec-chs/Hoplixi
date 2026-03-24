import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/di_init.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_repository.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_service.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/store_sync_binding_service.dart';
import 'package:hoplixi/features/cloud_sync/storage/providers/cloud_storage_provider.dart';

final storeSyncBindingServiceProvider = Provider<StoreSyncBindingService>((
  ref,
) {
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
