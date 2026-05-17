import 'package:drift/drift.dart';

import '../../../main_store.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../../../tables/vault_items/vault_snapshots_history.dart';


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

  Future<int> deleteSnapshotById(String historyId) {
    return (delete(vaultSnapshotsHistory)..where((t) => t.id.equals(historyId)))
        .go();
  }

  Future<List<String>> getSnapshotIdsForItem({
    required String itemId,
    required VaultItemType type,
  }) async {
    final rows = await (selectOnly(vaultSnapshotsHistory)
          ..addColumns([vaultSnapshotsHistory.id])
          ..where(vaultSnapshotsHistory.itemId.equals(itemId))
          ..where(vaultSnapshotsHistory.type.equalsValue(type))
          ..orderBy([
            OrderingTerm(
              expression: vaultSnapshotsHistory.historyCreatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();

    return rows
        .map((row) => row.read(vaultSnapshotsHistory.id))
        .whereType<String>()
        .toList();
  }

  Future<List<VaultSnapshotHistoryData>> getSnapshotsForItem({
    required String itemId,
    required VaultItemType type,
  }) {
    return (select(vaultSnapshotsHistory)
          ..where((t) => t.itemId.equals(itemId))
          ..where((t) => t.type.equalsValue(type))
          ..orderBy([(t) => OrderingTerm.desc(t.historyCreatedAt)]))
        .get();
  }

  Future<List<String>> getSnapshotIdsOlderThan(DateTime threshold) async {
    final rows = await (selectOnly(vaultSnapshotsHistory)
          ..addColumns([vaultSnapshotsHistory.id])
          ..where(vaultSnapshotsHistory.historyCreatedAt.isSmallerThanValue(threshold)))
        .get();

    return rows
        .map((row) => row.read(vaultSnapshotsHistory.id))
        .whereType<String>()
        .toList();
  }

  Future<List<VaultSnapshotItemGroup>> getSnapshotItemGroups() async {
    final query = selectOnly(vaultSnapshotsHistory, distinct: true)
      ..addColumns([vaultSnapshotsHistory.itemId, vaultSnapshotsHistory.type]);
    
    final rows = await query.get();
    
    return rows.map((row) => VaultSnapshotItemGroup(
      itemId: row.read(vaultSnapshotsHistory.itemId)!,
      type: row.readWithConverter<VaultItemType, String>(vaultSnapshotsHistory.type)!,
    )).toList();
  }
}

class VaultSnapshotItemGroup {
  const VaultSnapshotItemGroup({
    required this.itemId,
    required this.type,
  });

  final String itemId;
  final VaultItemType type;
}

