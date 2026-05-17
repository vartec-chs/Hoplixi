import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/system/vault_item_tag_history.dart';

part 'vault_item_tag_history_dao.g.dart';

@DriftAccessor(tables: [VaultItemTagHistory])
class VaultItemTagHistoryDao extends DatabaseAccessor<MainStore>
    with _$VaultItemTagHistoryDaoMixin {
  VaultItemTagHistoryDao(super.db);

  Future<void> insertTagHistory(VaultItemTagHistoryCompanion companion) {
    return into(vaultItemTagHistory).insert(companion);
  }

  Future<List<VaultItemTagHistoryData>> getTagsBySnapshotHistoryId(
    String historyId,
  ) {
    return (select(
      vaultItemTagHistory,
    )..where((t) => t.historyId.equals(historyId))).get();
  }

  Future<VaultItemTagHistoryData?> getTagHistoryById(String id) {
    return (select(
      vaultItemTagHistory,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> deleteTagHistoryById(String id) {
    return (delete(vaultItemTagHistory)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteTagsBySnapshotHistoryId(String snapshotHistoryId) {
    return (delete(
      vaultItemTagHistory,
    )..where((t) => t.historyId.equals(snapshotHistoryId))).go();
  }
}
