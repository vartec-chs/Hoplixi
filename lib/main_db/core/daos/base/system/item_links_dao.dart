import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/system/item_link/item_links.dart';

part 'item_links_dao.g.dart';

@DriftAccessor(tables: [ItemLinks])
class ItemLinksDao extends DatabaseAccessor<MainStore>
    with _$ItemLinksDaoMixin {
  ItemLinksDao(super.db);

  Future<int> insertItemLink(ItemLinksCompanion companion) {
    return into(itemLinks).insert(companion);
  }

  Future<int> updateItemLinkById(String id, ItemLinksCompanion companion) {
    return (update(itemLinks)..where((t) => t.id.equals(id))).write(companion);
  }

  Future<ItemLinksData?> getItemLinkById(String id) {
    return (select(itemLinks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<ItemLinksData>> getLinksFromItem(String sourceItemId) {
    return (select(
      itemLinks,
    )..where((t) => t.sourceItemId.equals(sourceItemId))).get();
  }

  Future<List<ItemLinksData>> getLinksToItem(String targetItemId) {
    return (select(
      itemLinks,
    )..where((t) => t.targetItemId.equals(targetItemId))).get();
  }

  Future<List<ItemLinksData>> getAllLinksForItem(String itemId) {
    return (select(itemLinks)..where(
          (t) => t.sourceItemId.equals(itemId) | t.targetItemId.equals(itemId),
        ))
        .get();
  }

  Future<int> deleteItemLinkById(String id) {
    return (delete(itemLinks)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteLinksForItem(String itemId) {
    return (delete(itemLinks)..where(
          (t) => t.sourceItemId.equals(itemId) | t.targetItemId.equals(itemId),
        ))
        .go();
  }

  Future<void> insertRestoredLink(ItemLinksCompanion companion) {
    return into(itemLinks).insert(companion, mode: InsertMode.insertOrReplace);
  }

  Future<bool> existsLink(String id) async {
    final query = selectOnly(itemLinks)
      ..addColumns([itemLinks.id])
      ..where(itemLinks.id.equals(id));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<List<ItemLinksData>> getLinksByRelationType(
    ItemLinkType relationType,
  ) {
    return (select(
      itemLinks,
    )..where((t) => t.relationType.equals(relationType.name))).get();
  }
}
