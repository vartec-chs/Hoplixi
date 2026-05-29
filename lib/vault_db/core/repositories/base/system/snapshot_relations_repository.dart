import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import 'package:hoplixi/vault_db/core/vault_db.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';

class SnapshotRelationsRepository {
  final VaultDB db;

  SnapshotRelationsRepository(this.db);

  AsyncDBResult<Optional<String>> snapshotCategoryForItem({
    required String? categoryId,
  }) {
    return tryCatchAsync(
      () async {
        if (categoryId == null) return const None();

        final revisions = await db.categoryRevisionsDao
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

  AsyncDBResult<Unit> snapshotLinksForItem({
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
