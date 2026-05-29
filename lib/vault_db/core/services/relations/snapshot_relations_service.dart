import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/categories_dao.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/category_revisions_dao.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/item_link_history_dao.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/item_links_dao.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/item_tags_dao.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/tags_dao.dart';
import 'package:hoplixi/vault_db/core/daos/base/system/item_tag_history_dao.dart';
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
      categoryRevisionsDao = db.categoryRevisionsDao,
      itemTagHistoryDao = db.itemTagHistoryDao,
      itemLinkHistoryDao = db.itemLinkHistoryDao;

  final VaultDB db;

  final CategoriesDao categoriesDao;
  final TagsDao tagsDao;
  final ItemTagsDao itemTagsDao;
  final ItemLinksDao itemLinksDao;
  final CategoryRevisionsDao categoryRevisionsDao;
  final ItemTagHistoryDao itemTagHistoryDao;
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

        final revisions = await categoryRevisionsDao
            .getCategoryRevisionsByOriginalCategoryId(categoryId);

        if (revisions.isEmpty) {
          throw DBCoreError.validation(
            code: 'category_revision_not_found',
            message: 'Category revision not found for category $categoryId',
          );
        }

        return Some(revisions.first.id);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении снимка категории',
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
          await itemTagHistoryDao.insertTagHistory(
            ItemTagHistoryCompanion.insert(
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
