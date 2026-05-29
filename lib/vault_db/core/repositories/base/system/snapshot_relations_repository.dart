import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import 'package:hoplixi/vault_db/core/vault_db.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';

class SnapshotRelationsRepository {
  final VaultDB db;

  SnapshotRelationsRepository(this.db);

  AsyncDbResult<Optional<String>> snapshotCategoryForItem({
    required String? categoryId,
  }) {
    return tryCatchAsync(
      () async {
        if (categoryId == null) return const None();

        final category = await db.categoriesDao.getCategoryById(categoryId);
        if (category == null) return const None();

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

        return Some(categoryHistoryId);
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

  AsyncDbResult<Unit> snapshotTagsForItem({
    required String historyId,
    required String itemId,
  }) {
    return tryCatchAsync(
      () async {
        final now = DateTime.now();
        final itemTags = await db.itemTagsDao.getTagsForItem(itemId);
        if (itemTags.isEmpty) return unit;

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

  AsyncDbResult<Unit> snapshotLinksForItem({
    required String historyId,
    required String itemId,
  }) {
    return tryCatchAsync(
      () async {
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
