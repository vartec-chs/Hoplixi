import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/dao/system/categories_dao.dart';
import 'package:hoplixi/main_db/core/dao/system/item_links_dao.dart';
import 'package:hoplixi/main_db/core/dao/system/item_tags_dao.dart';
import 'package:hoplixi/main_db/core/dao/system/tags_dao.dart';
import 'package:hoplixi/main_db/core/dao/vault_items/vault_items_dao.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/models/dto/system/item_link_dto.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';

class VaultItemRelationsService {
  VaultItemRelationsService({
    required this.db,
    required this.vaultItemsDao,
    required this.categoriesDao,
    required this.tagsDao,
    required this.itemTagsDao,
    required this.itemLinksDao,
  });

  final MainStore db;
  final VaultItemsDao vaultItemsDao;
  final CategoriesDao categoriesDao;
  final TagsDao tagsDao;
  final ItemTagsDao itemTagsDao;
  final ItemLinksDao itemLinksDao;

  // --- Tags ---

  Future<void> replaceTags({
    required String itemId,
    required List<String> tagIds,
  }) async {
    await db.transaction(() async {
      final exists = await vaultItemsDao.existsVaultItem(itemId);
      if (!exists) {
        throw Exception('Vault item not found: $itemId');
      }

      final uniqueTagIds = tagIds.toSet().toList();
      for (final tagId in uniqueTagIds) {
        final tagExists = await tagsDao.existsTag(tagId);
        if (!tagExists) {
          throw Exception('Tag not found: $tagId');
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
        if (tagId == null) {
          continue; // Skip null tag IDs
        }
        await itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
      }
    });
  }

  Future<void> addTags({
    required String itemId,
    required List<String> tagIds,
  }) async {
    await db.transaction(() async {
      for (final tagId in tagIds) {
        final tagExists = await tagsDao.existsTag(tagId);
        if (!tagExists) {
          throw Exception('Tag not found: $tagId');
        }
        await itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
      }
    });
  }

  Future<void> removeTags({
    required String itemId,
    required List<String> tagIds,
  }) async {
    await db.transaction(() async {
      for (final tagId in tagIds) {
        await itemTagsDao.removeTagFromItem(itemId: itemId, tagId: tagId);
      }
    });
  }

  Future<void> clearTags(String itemId) async {
    await itemTagsDao.removeAllTagsFromItem(itemId);
  }

  Future<List<String>> getTagIdsForItem(String itemId) async {
    final tags = await itemTagsDao.getTagsForItem(itemId);
    return tags.map((t) => t.tagId).toList();
  }

  // --- Category ---

  Future<void> changeCategory({
    required String itemId,
    required String? categoryId,
  }) async {
    await db.transaction(() async {
      if (categoryId != null) {
        final categoryExists = await categoriesDao.existsCategory(categoryId);
        if (!categoryExists) {
          throw Exception('Category not found: $categoryId');
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
  }

  Future<String?> getCategoryIdForItem(String itemId) async {
    final item = await vaultItemsDao.getVaultItemById(itemId);
    return item?.categoryId;
  }

  // --- Item Links ---

  Future<String> createLink(CreateItemLinkDto dto) async {
    return await db.transaction(() async {
      if (dto.sourceItemId == dto.targetItemId) {
        throw Exception('Source and target item IDs must be different');
      }

      final sourceExists = await vaultItemsDao.existsVaultItem(
        dto.sourceItemId,
      );
      if (!sourceExists) {
        throw Exception('Source item not found: ${dto.sourceItemId}');
      }

      final targetExists = await vaultItemsDao.existsVaultItem(
        dto.targetItemId,
      );
      if (!targetExists) {
        throw Exception('Target item not found: ${dto.targetItemId}');
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
      return id;
    });
  }

  Future<void> updateLink(PatchItemLinkDto dto) async {
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
  }

  Future<void> deleteLink(String linkId) async {
    await itemLinksDao.deleteItemLinkById(linkId);
  }
}
