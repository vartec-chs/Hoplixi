import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import 'package:hoplixi/vault_db/core/vault_db.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/system/item_link/item_links.dart';
import '../../../models/mappers/system/item_link_mapper.dart';
import '../../../models/mappers/system/tag_mapper.dart';

class VaultItemRelationsRepository {
  final VaultDB db;

  VaultItemRelationsRepository(this.db);

  AsyncDbResult<Unit> replaceTags({
    required String itemId,
    required List<String> tagIds,
  }) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        await db.itemTagsDao.removeAllTagsFromItem(itemId);
        for (final tagId in tagIds) {
          await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
        }
        return unit;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при замене тегов элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> addTags({
    required String itemId,
    required List<String> tagIds,
  }) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        for (final tagId in tagIds) {
          await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
        }
        return unit;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при добавлении тегов элементу',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> removeTags({
    required String itemId,
    required List<String> tagIds,
  }) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        for (final tagId in tagIds) {
          await db.itemTagsDao.removeTagFromItem(itemId: itemId, tagId: tagId);
        }
        return unit;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении тегов у элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> clearTags(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.itemTagsDao.removeAllTagsFromItem(itemId);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при очистке тегов элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<String>> getTagIdsForItem(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await db.itemTagsDao.getTagsForItem(itemId);
        return rows.map((r) => r.tagId).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении ID тегов элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<TagCardDto>> getTagsForItem(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final itemTags = await db.itemTagsDao.getTagsForItem(itemId);
        if (itemTags.isEmpty) return [];

        final tagIds = itemTags.map((it) => it.tagId).toList();
        final tags = await db.tagsDao.getTagsByIds(tagIds);
        return tags.map((t) => t.toTagCardDto()).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении тегов элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> changeCategory({
    required String itemId,
    required String? categoryId,
  }) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        if (categoryId != null) {
          final exists = await db.categoriesDao.existsCategory(categoryId);
          if (!exists) {
            throw DBCoreError.notFound(
              entity: 'categories',
              id: categoryId,
              message: 'Category not found',
            );
          }
        }

        await db.vaultItemsDao.updateVaultItemById(
          itemId,
          VaultItemsCompanion(
            categoryId: drift.Value(categoryId),
            modifiedAt: drift.Value(DateTime.now()),
          ),
        );
        return unit;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при смене категории элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<String>> getCategoryIdForItem(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final item = await db.vaultItemsDao.getVaultItemById(itemId);
        return Optional.fromNullable(item?.categoryId);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении ID категории элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<String> createLink(CreateItemLinkDto dto) {
    return ResultUtils.tryCatchAsync(
      () async {
        if (dto.sourceItemId == dto.targetItemId) {
          throw const DBCoreError.validation(
            code: 'item_link.self_link',
            message: 'Source and target items cannot be the same',
          );
        }

        if (dto.relationType == ItemLinkType.other) {
          if (dto.relationTypeOther == null ||
              dto.relationTypeOther!.trim().isEmpty) {
            throw const DBCoreError.validation(
              code: 'item_link.type_other_missing',
              message:
                  'relationTypeOther is required when relationType is other',
            );
          }
        }

        final id = const Uuid().v4();
        final now = DateTime.now();

        await db.itemLinksDao.insertItemLink(
          ItemLinksCompanion.insert(
            id: drift.Value(id),
            sourceItemId: dto.sourceItemId,
            targetItemId: dto.targetItemId,
            relationType: dto.relationType,
            relationTypeOther: drift.Value(dto.relationTypeOther),
            label: drift.Value(dto.label),
            sortOrder: drift.Value(dto.sortOrder),
            createdAt: drift.Value(now),
            modifiedAt: drift.Value(now),
          ),
        );

        return id;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании связи между элементами',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> updateLink(PatchItemLinkDto dto) {
    return ResultUtils.tryCatchAsync(
      () async {
        final companion = ItemLinksCompanion(
          relationType: dto.relationType.toRequiredValue(),
          relationTypeOther: dto.relationTypeOther.toNullableValue(),
          label: dto.label.toNullableValue(),
          sortOrder: dto.sortOrder.toRequiredValue(),
          modifiedAt: drift.Value(DateTime.now()),
        );

        final count = await db.itemLinksDao.updateItemLinkById(
          dto.id,
          companion,
        );
        if (count == 0) {
          throw DBCoreError.notFound(entity: 'item_links', id: dto.id);
        }
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении связи между элементами',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deleteLink(String linkId) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.itemLinksDao.deleteItemLinkById(linkId);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении связи между элементами',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<ItemLinkViewDto>> getLinksFromItem(String sourceItemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await db.itemLinksDao.getLinksFromItem(sourceItemId);
        return rows.map((r) => r.toItemLinkViewDto()).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении исходящих связей элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<ItemLinkViewDto>> getLinksToItem(String targetItemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await db.itemLinksDao.getLinksToItem(targetItemId);
        return rows.map((r) => r.toItemLinkViewDto()).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении входящих связей элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<ItemLinkViewDto>> getAllLinksForItem(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await db.itemLinksDao.getAllLinksForItem(itemId);
        return rows.map((r) => r.toItemLinkViewDto()).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении всех связей элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
