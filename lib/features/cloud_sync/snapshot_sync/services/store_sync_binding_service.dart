import 'package:hive_ce/hive.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';

class StoreSyncBindingService {
  StoreSyncBindingService(this._hiveBoxManager);

  static const String _boxName = 'cloud_sync_store_bindings';

  final HiveBoxManager _hiveBoxManager;
  Box<Map>? _box;

  Future<void> initialize() async {
    if (_box?.isOpen ?? false) {
      return;
    }
    _box = await _hiveBoxManager.openBox<Map>(_boxName);
  }

  Future<StoreSyncBinding?> getByStoreUuid(String storeUuid) async {
    await initialize();
    final raw = _box!.get(storeUuid);
    if (raw == null) {
      return null;
    }

    return StoreSyncBinding.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<StoreSyncBinding> saveBinding({
    required String storeUuid,
    required String tokenId,
    required CloudSyncProvider provider,
  }) async {
    await initialize();
    final now = DateTime.now().toUtc();
    final existing = await getByStoreUuid(storeUuid);
    final binding = StoreSyncBinding(
      storeUuid: storeUuid,
      tokenId: tokenId,
      provider: provider,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _box!.put(storeUuid, binding.toJson());
    return binding;
  }

  Future<void> deleteBinding(String storeUuid) async {
    await initialize();
    await _box!.delete(storeUuid);
  }

  Future<void> dispose() async {
    if (!(_box?.isOpen ?? false)) {
      return;
    }
    await _hiveBoxManager.closeBox(_boxName);
    _box = null;
  }
}
