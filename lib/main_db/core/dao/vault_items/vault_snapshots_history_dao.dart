import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/vault_items/vault_snapshots_history.dart';

part 'vault_snapshots_history_dao.g.dart';

@DataClassName('VaultSnapshotHistoryData')
@DriftAccessor(tables: [VaultSnapshotsHistory])
class VaultSnapshotsHistoryDao extends DatabaseAccessor<MainStore>
    with _$VaultSnapshotsHistoryDaoMixin {
  VaultSnapshotsHistoryDao(super.db);

  Future<int> insertVaultSnapshot(VaultSnapshotsHistoryCompanion companion) {
    return into(vaultSnapshotsHistory).insert(companion);
  }

  Future<VaultSnapshotHistoryData?> getSnapshotById(String historyId) {
    return (select(vaultSnapshotsHistory)..where((t) => t.id.equals(historyId)))
        .getSingleOrNull();
  }
}
