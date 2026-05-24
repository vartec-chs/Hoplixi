import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../../scheme/tables/system/item_tags.dart';

part 'item_tags_dao.g.dart';

@DriftAccessor(tables: [ItemTags])
class ItemTagsDao extends DatabaseAccessor<VaultDB> with _$ItemTagsDaoMixin {
  ItemTagsDao(super.db);

  Future<void> assignTagToItem({
    required String itemId,
    required String tagId,
  }) {
    return into(itemTags).insert(
      ItemTagsCompanion.insert(itemId: itemId, tagId: tagId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<int> removeTagFromItem({
    required String itemId,
    required String tagId,
  }) {
    return (delete(
      itemTags,
    )..where((t) => t.itemId.equals(itemId) & t.tagId.equals(tagId))).go();
  }

  Future<List<ItemTagsData>> getTagsForItem(String itemId) {
    return (select(itemTags)..where((t) => t.itemId.equals(itemId))).get();
  }

  Future<List<ItemTagsData>> getItemsForTag(String tagId) {
    return (select(itemTags)..where((t) => t.tagId.equals(tagId))).get();
  }

  Future<bool> itemHasTag({
    required String itemId,
    required String tagId,
  }) async {
    final query = selectOnly(itemTags)
      ..where(itemTags.itemId.equals(itemId) & itemTags.tagId.equals(tagId));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<int> removeAllTagsFromItem(String itemId) {
    return (delete(itemTags)..where((t) => t.itemId.equals(itemId))).go();
  }
}
