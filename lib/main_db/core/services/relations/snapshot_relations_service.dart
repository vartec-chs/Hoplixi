import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/dao/system/categories_dao.dart';
import 'package:hoplixi/main_db/core/dao/system/item_category_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/system/item_link_history_dao.dart';
import 'package:hoplixi/main_db/core/dao/system/item_links_dao.dart';
import 'package:hoplixi/main_db/core/dao/system/item_tags_dao.dart';
import 'package:hoplixi/main_db/core/dao/system/tags_dao.dart';
import 'package:hoplixi/main_db/core/dao/system/vault_item_tag_history_dao.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';

class SnapshotRelationsService {
  SnapshotRelationsService({
    required this.categoriesDao,
    required this.tagsDao,
    required this.itemTagsDao,
    required this.itemLinksDao,
    required this.itemCategoryHistoryDao,
    required this.vaultItemTagHistoryDao,
    required this.itemLinkHistoryDao,
  });

  final CategoriesDao categoriesDao;
  final TagsDao tagsDao;
  final ItemTagsDao itemTagsDao;
  final ItemLinksDao itemLinksDao;
  final ItemCategoryHistoryDao itemCategoryHistoryDao;
  final VaultItemTagHistoryDao vaultItemTagHistoryDao;
  final ItemLinkHistoryDao itemLinkHistoryDao;

  Future<String?> snapshotCategoryForItem({
    required String? categoryId,
    String? snapshotId,
    String? itemId,
  }) async {
    if (categoryId == null) {
      return null;
    }

    final category = await categoriesDao.getCategoryById(categoryId);
    if (category == null) {
      // Можно бросить ошибку или вернуть null. 
      // По инструкции: "лучше вернуть null и оставить categoryId в vault_snapshots_history"
      return null;
    }

    final id = const Uuid().v4();
    await itemCategoryHistoryDao.insertCategoryHistory(
      ItemCategoryHistoryCompanion.insert(
        id: Value(id),
        snapshotId: Value(snapshotId),
        itemId: Value(itemId),
        categoryId: Value(category.id),
        name: category.name,
        description: Value(category.description),
        iconRefId: Value(category.iconRefId),
        color: category.color,
        type: category.type,
        parentId: Value(category.parentId),
        categoryCreatedAt: Value(category.createdAt),
        categoryModifiedAt: Value(category.modifiedAt),
      ),
    );

    return id;
  }

  Future<void> snapshotTagsForItem({
    required String historyId,
    required String itemId,
  }) async {
    final itemTags = await itemTagsDao.getTagsForItem(itemId);
    if (itemTags.isEmpty) return;

    final tagIds = itemTags.map((t) => t.tagId).toList();
    final tags = await tagsDao.getTagsByIds(tagIds);

    for (final tag in tags) {
      await vaultItemTagHistoryDao.insertTagHistory(
        VaultItemTagHistoryCompanion.insert(
          historyId: Value(historyId),
          itemId: Value(itemId),
          tagId: Value(tag.id),
          name: tag.name,
          color: tag.color,
          type: tag.type,
          tagCreatedAt: Value(tag.createdAt),
          tagModifiedAt: Value(tag.modifiedAt),
        ),
      );
    }
  }

  Future<void> snapshotLinksForItem({
    required String historyId,
    required String itemId,
  }) async {
    final links = await itemLinksDao.getAllLinksForItem(itemId);
    if (links.isEmpty) return;

    for (final link in links) {
      await itemLinkHistoryDao.insertItemLinkHistory(
        ItemLinkHistoryCompanion.insert(
          historyId: historyId,
          sourceLinkId: Value(link.id),
          sourceItemId: link.sourceItemId,
          targetItemId: link.targetItemId,
          relationType: link.relationType,
          relationTypeOther: Value(link.relationTypeOther),
          label: Value(link.label),
          sortOrder: Value(link.sortOrder),
          createdAt: link.createdAt,
          modifiedAt: link.modifiedAt,
        ),
      );
    }
  }
}
