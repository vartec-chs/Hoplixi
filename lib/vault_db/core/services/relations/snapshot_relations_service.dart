import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/categories_dao.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/item_category_history_dao.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/item_link_history_dao.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/item_links_dao.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/item_tags_dao.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/tags_dao.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/vault_item_tag_history_dao.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import 'package:hoplixi/vault_db/core/vault_db.dart';
import '../../errors/db_error.dart';
import '../../errors/db_result.dart';

class SnapshotRelationsService {
  SnapshotRelationsService({required this.db})
    : categoriesDao = db.categoriesDao,
      tagsDao = db.tagsDao,
      itemTagsDao = db.itemTagsDao,
      itemLinksDao = db.itemLinksDao,
      itemCategoryHistoryDao = db.itemCategoryHistoryDao,
      vaultItemTagHistoryDao = db.vaultItemTagHistoryDao,
      itemLinkHistoryDao = db.itemLinkHistoryDao;

  final VaultDB db;

  final CategoriesDao categoriesDao;
  final TagsDao tagsDao;
  final ItemTagsDao itemTagsDao;
  final ItemLinksDao itemLinksDao;
  final ItemCategoryHistoryDao itemCategoryHistoryDao;
  final VaultItemTagHistoryDao vaultItemTagHistoryDao;
  final ItemLinkHistoryDao itemLinkHistoryDao;

  AsyncDBResult<Optional<String>> snapshotCategoryForItem({
    required String? categoryId,
    String? snapshotId,
    String? itemId,
  }) {
    return tryCatchAsync(
      () async {
        if (categoryId == null) {
          return const None();
        }

        final category = await categoriesDao.getCategoryById(categoryId);
        if (category == null) {
          return const None();
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

        return Some(id);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании снимка категории',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> snapshotTagsForItem({
    required String historyId,
    required String itemId,
  }) {
    return tryCatchAsync(
      () async {
        final itemTags = await itemTagsDao.getTagsForItem(itemId);
        if (itemTags.isEmpty) return unit;

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
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании снимка тегов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> snapshotLinksForItem({
    required String historyId,
    required String itemId,
  }) {
    return tryCatchAsync(
      () async {
        final links = await itemLinksDao.getAllLinksForItem(itemId);
        if (links.isEmpty) return unit;

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
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании снимка связей',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
