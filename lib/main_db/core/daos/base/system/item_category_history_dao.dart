import 'package:drift/drift.dart';
import '../../../main_store.dart';
import '../../../tables/system/item_category_history.dart';

part 'item_category_history_dao.g.dart';

@DriftAccessor(tables: [ItemCategoryHistory])
class ItemCategoryHistoryDao extends DatabaseAccessor<MainStore>
    with _$ItemCategoryHistoryDaoMixin {
  ItemCategoryHistoryDao(super.db);

  Future<void> insertCategoryHistory(ItemCategoryHistoryCompanion companion) {
    return into(itemCategoryHistory).insert(companion);
  }

  Future<ItemCategoryHistoryData?> getCategoryHistoryById(String id) {
    return (select(itemCategoryHistory)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<ItemCategoryHistoryData>> getCategoryHistoryByOriginalCategoryId(
    String originalCategoryId,
  ) {
    return (select(itemCategoryHistory)
          ..where((t) => t.categoryId.equals(originalCategoryId)))
        .get();
  }

  Future<int> deleteCategoryHistoryById(String id) {
    return (delete(itemCategoryHistory)..where((t) => t.id.equals(id))).go();
  }
}
