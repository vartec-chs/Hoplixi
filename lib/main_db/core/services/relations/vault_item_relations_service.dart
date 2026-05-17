import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/daos/base/system/categories_dao.dart';
import 'package:hoplixi/main_db/core/daos/base/system/item_links_dao.dart';
import 'package:hoplixi/main_db/core/daos/base/system/item_tags_dao.dart';
import 'package:hoplixi/main_db/core/daos/base/system/tags_dao.dart';
import 'package:hoplixi/main_db/core/daos/base/vault_items/vault_items_dao.dart';
import 'package:hoplixi/main_db/core/errors/db_error.dart';
import 'package:hoplixi/main_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/main_db/core/errors/db_result.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/models/dto/system/item_link_dto.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';

class VaultItemRelationsService {
  VaultItemRelationsService({required this.db})
    : vaultItemsDao = db.vaultItemsDao,
      categoriesDao = db.categoriesDao,
      tagsDao = db.tagsDao,
      itemTagsDao = db.itemTagsDao,
      itemLinksDao = db.itemLinksDao;

  final MainStore db;
  final VaultItemsDao vaultItemsDao;
  final CategoriesDao categoriesDao;
  final TagsDao tagsDao;
  final ItemTagsDao itemTagsDao;
  final ItemLinksDao itemLinksDao;

  // --- Tags ---

  Future<DbResult<Unit>> replaceTags({
    required String itemId,
    required List<String> tagIds,
  }) async {
    try {
      await db.transaction(() async {
        final exists = await vaultItemsDao.existsVaultItem(itemId);
        if (!exists) {
          throw DBCoreError.notFound(
            entity: 'vaultItem',
            id: itemId,
            message: 'Vault item not found: $itemId',
          );
        }

        final uniqueTagIds = tagIds.toSet().toList();
        for (final tagId in uniqueTagIds) {
          final tagExists = await tagsDao.existsTag(tagId);
          if (!tagExists) {
            throw DBCoreError.notFound(
              entity: 'tag',
              id: tagId,
              message: 'Tag not found: $tagId',
            );
          }
        }

        final currentTags = await itemTagsDao.getTagsForItem(itemId);
        final currentTagIds = currentTags.map((t) => t.tagId).toSet();

        final tagsToRemove = currentTagIds.difference(uniqueTagIds.toSet());
        final tagsToAdd = uniqueTagIds.toSet().difference(currentTagIds);

        for (final tagId in tagsToRemove) {
          await itemTagsDao.removeTagFromItem(itemId: itemId, tagId: tagId);
        }

        for (final tagId in tagsToAdd) {
          await itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
        }
      });
      return const Success(unit);
    } on DBCoreError catch (e) {
      return Failure(e);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<DbResult<Unit>> addTags({
    required String itemId,
    required List<String> tagIds,
  }) async {
    try {
      await db.transaction(() async {
        for (final tagId in tagIds) {
          final tagExists = await tagsDao.existsTag(tagId);
          if (!tagExists) {
            throw DBCoreError.notFound(
              entity: 'tag',
              id: tagId,
              message: 'Tag not found: $tagId',
            );
          }
          await itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
        }
      });
      return const Success(unit);
    } on DBCoreError catch (e) {
      return Failure(e);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<DbResult<Unit>> removeTags({
    required String itemId,
    required List<String> tagIds,
  }) async {
    try {
      await db.transaction(() async {
        for (final tagId in tagIds) {
          await itemTagsDao.removeTagFromItem(itemId: itemId, tagId: tagId);
        }
      });
      return const Success(unit);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<DbResult<Unit>> clearTags(String itemId) async {
    try {
      await itemTagsDao.removeAllTagsFromItem(itemId);
      return const Success(unit);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<List<String>> getTagIdsForItem(String itemId) async {
    final tags = await itemTagsDao.getTagsForItem(itemId);
    return tags.map((t) => t.tagId).toList();
  }

  // --- Category ---

  Future<DbResult<Unit>> changeCategory({
    required String itemId,
    required String? categoryId,
  }) async {
    try {
      await db.transaction(() async {
        if (categoryId != null) {
          final categoryExists = await categoriesDao.existsCategory(categoryId);
          if (!categoryExists) {
            throw DBCoreError.notFound(
              entity: 'category',
              id: categoryId,
              message: 'Category not found: $categoryId',
            );
          }
        }

        await vaultItemsDao.updateVaultItemById(
          itemId,
          VaultItemsCompanion(
            categoryId: Value(categoryId),
            modifiedAt: Value(DateTime.now()),
          ),
        );
      });
      return const Success(unit);
    } on DBCoreError catch (e) {
      return Failure(e);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<String?> getCategoryIdForItem(String itemId) async {
    final item = await vaultItemsDao.getVaultItemById(itemId);
    return item?.categoryId;
  }

  // --- Item Links ---

  Future<DbResult<String>> createLink(CreateItemLinkDto dto) async {
    try {
      return await db.transaction(() async {
        if (dto.sourceItemId == dto.targetItemId) {
          throw const DBCoreError.validation(
            code: 'item_link.source_target_same',
            message: 'Source and target item IDs must be different',
          );
        }

        final sourceExists = await vaultItemsDao.existsVaultItem(
          dto.sourceItemId,
        );
        if (!sourceExists) {
          throw DBCoreError.notFound(
            entity: 'vaultItem',
            id: dto.sourceItemId,
            message: 'Source item not found: ${dto.sourceItemId}',
          );
        }

        final targetExists = await vaultItemsDao.existsVaultItem(
          dto.targetItemId,
        );
        if (!targetExists) {
          throw DBCoreError.notFound(
            entity: 'vaultItem',
            id: dto.targetItemId,
            message: 'Target item not found: ${dto.targetItemId}',
          );
        }

        final id = const Uuid().v4();
        await itemLinksDao.insertItemLink(
          ItemLinksCompanion.insert(
            id: Value(id),
            sourceItemId: dto.sourceItemId,
            targetItemId: dto.targetItemId,
            relationType: dto.relationType,
            relationTypeOther: Value(dto.relationTypeOther),
            label: Value(dto.label),
            sortOrder: Value(dto.sortOrder),
            createdAt: Value(DateTime.now()),
            modifiedAt: Value(DateTime.now()),
          ),
        );
        return Success(id);
      });
    } on DBCoreError catch (e) {
      return Failure(e);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<DbResult<Unit>> updateLink(PatchItemLinkDto dto) async {
    try {
      await itemLinksDao.updateItemLinkById(
        dto.id,
        ItemLinksCompanion(
          relationType: dto.relationType.toRequiredValue(),
          relationTypeOther: dto.relationTypeOther.toNullableValue(),
          label: dto.label.toNullableValue(),
          sortOrder: dto.sortOrder.toRequiredValue(),
          modifiedAt: Value(DateTime.now()),
        ),
      );
      return const Success(unit);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<DbResult<Unit>> deleteLink(String linkId) async {
    try {
      await itemLinksDao.deleteItemLinkById(linkId);
      return const Success(unit);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }
}
