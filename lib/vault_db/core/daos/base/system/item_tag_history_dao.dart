import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../../scheme/tables/system/tags/item_tag_history.dart';

part 'item_tag_history_dao.g.dart';

@DriftAccessor(tables: [ItemTagHistory])
class ItemTagHistoryDao extends DatabaseAccessor<VaultDB>
    with _$ItemTagHistoryDaoMixin {
  ItemTagHistoryDao(super.db);

  Future<void> insertTagHistory(ItemTagHistoryCompanion companion) {
    return into(itemTagHistory).insert(companion);
  }

  Future<List<ItemTagHistoryData>> getTagsBySnapshotHistoryId(
    String historyId,
  ) {
    return (select(
      itemTagHistory,
    )..where((t) => t.historyId.equals(historyId))).get();
  }

  Future<ItemTagHistoryData?> getTagHistoryById(String id) {
    return (select(
      itemTagHistory,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> deleteTagHistoryById(String id) {
    return (delete(itemTagHistory)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteTagsBySnapshotHistoryId(String snapshotHistoryId) {
    return (delete(
      itemTagHistory,
    )..where((t) => t.historyId.equals(snapshotHistoryId))).go();
  }
}
