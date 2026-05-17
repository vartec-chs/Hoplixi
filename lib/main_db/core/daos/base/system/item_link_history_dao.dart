import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/system/item_link/item_link_history.dart';

part 'item_link_history_dao.g.dart';

@DriftAccessor(tables: [ItemLinkHistory])
class ItemLinkHistoryDao extends DatabaseAccessor<MainStore>
    with _$ItemLinkHistoryDaoMixin {
  ItemLinkHistoryDao(super.db);

  Future<void> insertItemLinkHistory(ItemLinkHistoryCompanion companion) {
    return into(itemLinkHistory).insert(companion);
  }

  Future<ItemLinkHistoryData?> getItemLinkHistoryById(String id) {
    return (select(itemLinkHistory)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<ItemLinkHistoryData>> getLinksBySnapshotHistoryId(
    String historyId,
  ) {
    return (select(itemLinkHistory)..where((t) => t.historyId.equals(historyId)))
        .get();
  }

  Future<List<ItemLinkHistoryData>> getLinksBySourceItemId(String sourceItemId) {
    return (select(itemLinkHistory)
          ..where((t) => t.sourceItemId.equals(sourceItemId)))
        .get();
  }

  Future<List<ItemLinkHistoryData>> getLinksByTargetItemId(String targetItemId) {
    return (select(itemLinkHistory)
          ..where((t) => t.targetItemId.equals(targetItemId)))
        .get();
  }

  Future<int> deleteItemLinkHistoryById(String id) {
    return (delete(itemLinkHistory)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteLinksBySnapshotHistoryId(String snapshotHistoryId) {
    return (delete(itemLinkHistory)
          ..where((t) => t.historyId.equals(snapshotHistoryId)))
        .go();
  }
}
