import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../main_store.dart';
import '../../../tables/system/item_link/item_links.dart';
import '../../../models/dto/system/item_link_dto.dart';
import '../../../models/mappers/system/item_link_mapper.dart';
import '../../../models/dto/system/tag_dto.dart';
import '../../../models/mappers/system/tag_mapper.dart';

class VaultItemRelationsRepository   {
  final MainStore db;

  VaultItemRelationsRepository(this.db);

  Future<void> replaceTags({
    required String itemId,
    required List<String> tagIds,
  }) async {
    return db.transaction(() async {
      await db.itemTagsDao.removeAllTagsFromItem(itemId);
      for (final tagId in tagIds) {
        await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
      }
    });
  }

  Future<void> addTags({
    required String itemId,
    required List<String> tagIds,
  }) async {
    return db.transaction(() async {
      for (final tagId in tagIds) {
        await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
      }
    });
  }

  Future<void> removeTags({
    required String itemId,
    required List<String> tagIds,
  }) async {
    return db.transaction(() async {
      for (final tagId in tagIds) {
        await db.itemTagsDao.removeTagFromItem(itemId: itemId, tagId: tagId);
      }
    });
  }

  Future<void> clearTags(String itemId) {
    return db.itemTagsDao.removeAllTagsFromItem(itemId);
  }

  Future<List<String>> getTagIdsForItem(String itemId) async {
    final rows = await db.itemTagsDao.getTagsForItem(itemId);
    return rows.map((r) => r.tagId).toList();
  }

  Future<List<TagCardDto>> getTagsForItem(String itemId) async {
    final itemTags = await db.itemTagsDao.getTagsForItem(itemId);
    if (itemTags.isEmpty) return [];

    final tagIds = itemTags.map((it) => it.tagId).toList();
    final tags = await db.tagsDao.getTagsByIds(tagIds);
    return tags.map((t) => t.toTagCardDto()).toList();
  }

  Future<void> changeCategory({
    required String itemId,
    required String? categoryId,
  }) async {
    return db.transaction(() async {
      if (categoryId != null) {
        final exists = await db.categoriesDao.existsCategory(categoryId);
        if (!exists) {
          throw ArgumentError('Category not found');
        }
      }

      await db.vaultItemsDao.updateVaultItemById(
        itemId,
        VaultItemsCompanion(
          categoryId: drift.Value(categoryId),
          modifiedAt: drift.Value(DateTime.now()),
        ),
      );
    });
  }

  Future<String?> getCategoryIdForItem(String itemId) async {
    final item = await db.vaultItemsDao.getVaultItemById(itemId);
    return item?.categoryId;
  }

  Future<String> createLink(CreateItemLinkDto dto) async {
    if (dto.sourceItemId == dto.targetItemId) {
      throw ArgumentError('Source and target items cannot be the same');
    }

    if (dto.relationType == ItemLinkType.other) {
      if (dto.relationTypeOther == null || dto.relationTypeOther!.trim().isEmpty) {
        throw ArgumentError('relationTypeOther is required when relationType is other');
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
  }

  Future<void> updateLink(UpdateItemLinkDto dto) async {
    final companion = ItemLinksCompanion(
      relationType: dto.relationType != null ? drift.Value(dto.relationType!) : const drift.Value.absent(),
      relationTypeOther: dto.relationTypeOther != null ? drift.Value(dto.relationTypeOther) : const drift.Value.absent(),
      label: dto.label != null ? drift.Value(dto.label) : const drift.Value.absent(),
      sortOrder: dto.sortOrder != null ? drift.Value(dto.sortOrder!) : const drift.Value.absent(),
      modifiedAt: drift.Value(DateTime.now()),
    );

    await db.itemLinksDao.updateItemLinkById(dto.id, companion);
  }

  Future<void> deleteLink(String linkId) {
    return db.itemLinksDao.deleteItemLinkById(linkId);
  }

  Future<List<ItemLinkViewDto>> getLinksFromItem(String sourceItemId) async {
    final rows = await db.itemLinksDao.getLinksFromItem(sourceItemId);
    return rows.map((r) => r.toItemLinkViewDto()).toList();
  }

  Future<List<ItemLinkViewDto>> getLinksToItem(String targetItemId) async {
    final rows = await db.itemLinksDao.getLinksToItem(targetItemId);
    return rows.map((r) => r.toItemLinkViewDto()).toList();
  }

  Future<List<ItemLinkViewDto>> getAllLinksForItem(String itemId) async {
    final rows = await db.itemLinksDao.getAllLinksForItem(itemId);
    return rows.map((r) => r.toItemLinkViewDto()).toList();
  }
}
