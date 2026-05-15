import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../main_store.dart';

class SnapshotRelationsRepository {
  final MainStore db;

  SnapshotRelationsRepository(this.db);

  Future<String?> snapshotCategoryForItem({
    required String? categoryId,
  }) async {
    if (categoryId == null) return null;

    final category = await db.categoriesDao.getCategoryById(categoryId);
    if (category == null) return null;

    final categoryHistoryId = const Uuid().v4();
    final now = DateTime.now();

    await db.itemCategoryHistoryDao.insertCategoryHistory(
      ItemCategoryHistoryCompanion.insert(
        id: drift.Value(categoryHistoryId),
        categoryId: drift.Value(category.id),
        name: category.name,
        description: drift.Value(category.description),
        iconRefId: drift.Value(category.iconRefId),
        color: category.color,
        type: category.type,
        parentId: drift.Value(category.parentId),
        categoryCreatedAt: drift.Value(category.createdAt),
        categoryModifiedAt: drift.Value(category.modifiedAt),
        snapshotCreatedAt: drift.Value(now),
      ),
    );

    return categoryHistoryId;
  }

  Future<void> snapshotTagsForItem({
    required String historyId,
    required String itemId,
  }) async {
    final now = DateTime.now();
    final itemTags = await db.itemTagsDao.getTagsForItem(itemId);
    if (itemTags.isEmpty) return;

    final tagIds = itemTags.map((it) => it.tagId).toList();
    final tags = await db.tagsDao.getTagsByIds(tagIds);

    for (final tag in tags) {
      await db.vaultItemTagHistoryDao.insertTagHistory(
        VaultItemTagHistoryCompanion.insert(
          id: drift.Value(const Uuid().v4()),
          historyId: drift.Value(historyId),
          tagId: drift.Value(tag.id),
          name: tag.name,
          color: tag.color,
          type: tag.type,
          tagCreatedAt: drift.Value(tag.createdAt),
          tagModifiedAt: drift.Value(tag.modifiedAt),
          snapshotCreatedAt: drift.Value(now),
        ),
      );
    }
  }

  Future<void> snapshotLinksForItem({
    required String historyId,
    required String itemId,
  }) async {
    final now = DateTime.now();
    final links = await db.itemLinksDao.getAllLinksForItem(itemId);

    for (final link in links) {
      await db.itemLinkHistoryDao.insertItemLinkHistory(
        ItemLinkHistoryCompanion.insert(
          id: drift.Value(const Uuid().v4()),
          historyId: historyId,
          sourceLinkId: drift.Value(link.id),
          sourceItemId: link.sourceItemId,
          targetItemId: link.targetItemId,
          relationType: link.relationType,
          relationTypeOther: drift.Value(link.relationTypeOther),
          label: drift.Value(link.label),
          sortOrder: drift.Value(link.sortOrder),
          createdAt: link.createdAt,
          modifiedAt: link.modifiedAt,
          snapshotCreatedAt: drift.Value(now),
        ),
      );
    }
  }
}
