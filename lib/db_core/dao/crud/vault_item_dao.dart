import 'dart:math' show exp;

import 'package:drift/drift.dart';
import 'package:hoplixi/db_core/models/dto/category_dto.dart';
import 'package:hoplixi/db_core/models/dto/icon_ref_dto.dart';
import 'package:hoplixi/db_core/models/dto/linked_vault_item_card_dto.dart';
import 'package:hoplixi/db_core/models/dto/tag_dto.dart';
import 'package:hoplixi/db_core/main_store.dart';
import 'package:hoplixi/db_core/tables/item_tags.dart';
import 'package:hoplixi/db_core/tables/vault_items.dart';

part 'vault_item_dao.g.dart';

/// Базовый DAO для общих операций с vault_items.
///
/// Все операции с общими полями (toggle, soft delete,
/// increment usage) выполняются здесь. Type-specific DAO
/// вызывают этот DAO для общих операций.
@DriftAccessor(tables: [VaultItems, ItemTags])
class VaultItemDao extends DatabaseAccessor<MainStore>
    with _$VaultItemDaoMixin {
  VaultItemDao(super.db);

  /// Получить элемент по ID
  Future<VaultItemsData?> getById(String id) {
    return (select(
      vaultItems,
    )..where((v) => v.id.equals(id))).getSingleOrNull();
  }

  /// Переключить избранное
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final result = await (update(vaultItems)..where((v) => v.id.equals(id)))
        .write(VaultItemsCompanion(isFavorite: Value(isFavorite)));
    return result > 0;
  }

  /// Переключить закрепление
  Future<bool> togglePin(String id, bool isPinned) async {
    final result = await (update(vaultItems)..where((v) => v.id.equals(id)))
        .write(VaultItemsCompanion(isPinned: Value(isPinned)));
    return result > 0;
  }

  /// Переключить архивирование
  Future<bool> toggleArchive(String id, bool isArchived) async {
    final result = await (update(vaultItems)..where((v) => v.id.equals(id)))
        .write(VaultItemsCompanion(isArchived: Value(isArchived)));
    return result > 0;
  }

  /// Мягкое удаление
  Future<bool> softDelete(String id) async {
    final result = await (update(vaultItems)..where((v) => v.id.equals(id)))
        .write(const VaultItemsCompanion(isDeleted: Value(true)));
    return result > 0;
  }

  /// Восстановить из удалённых
  Future<bool> restoreFromDeleted(String id) async {
    final result = await (update(vaultItems)..where((v) => v.id.equals(id)))
        .write(const VaultItemsCompanion(isDeleted: Value(false)));
    return result > 0;
  }

  Future<bool> setIconRef(String id, IconRefDto? iconRef) async {
    final result = await (update(vaultItems)..where((v) => v.id.equals(id)))
        .write(
          VaultItemsCompanion(
            iconSource: Value(iconRef?.sourceValue),
            iconValue: Value(iconRef?.value),
            modifiedAt: Value(DateTime.now()),
          ),
        );
    return result > 0;
  }

  /// Полное удаление (CASCADE удалит type-specific)
  Future<bool> permanentDelete(String id) async {
    final result = await (delete(
      vaultItems,
    )..where((v) => v.id.equals(id))).go();
    return result > 0;
  }

  /// Увеличить счётчик и обновить EWMA recentScore
  Future<bool> incrementUsage(String id) async {
    final item = await getById(id);
    if (item == null) return false;

    final now = DateTime.now();
    final newCount = item.usedCount + 1;

    double newScore = 1.0;
    if (item.lastUsedAt != null && item.recentScore != null) {
      final delta = now.difference(item.lastUsedAt!).inSeconds.toDouble();
      final tau = const Duration(days: 7).inSeconds.toDouble();
      final decay = exp(-delta / tau);
      newScore = item.recentScore! * decay + 1.0;
    }

    final result = await (update(vaultItems)..where((v) => v.id.equals(id)))
        .write(
          VaultItemsCompanion(
            usedCount: Value(newCount),
            recentScore: Value(newScore),
            lastUsedAt: Value(now),
          ),
        );
    return result > 0;
  }

  /// Вставить теги для элемента
  Future<void> insertTags(String itemId, List<String>? tagIds) async {
    if (tagIds == null || tagIds.isEmpty) return;
    for (final tagId in tagIds) {
      await into(
        itemTags,
      ).insert(ItemTagsCompanion.insert(itemId: itemId, tagId: tagId));
    }
  }

  /// Получить ID тегов элемента
  Future<List<String>> getTagIds(String itemId) async {
    final rows = await (select(
      itemTags,
    )..where((t) => t.itemId.equals(itemId))).get();
    return rows.map((row) => row.tagId).toList();
  }

  /// Синхронизировать теги элемента (diff-based)
  Future<void> syncTags(String itemId, List<String> tagIds) async {
    await db.transaction(() async {
      final existing = await (select(
        itemTags,
      )..where((t) => t.itemId.equals(itemId))).get();
      final existingIds = existing.map((r) => r.tagId).toSet();
      final newIds = tagIds.toSet();

      final toDelete = existingIds.difference(newIds);
      if (toDelete.isNotEmpty) {
        await (delete(
          itemTags,
        )..where((t) => t.itemId.equals(itemId) & t.tagId.isIn(toDelete))).go();
      }

      final toInsert = newIds.difference(existingIds);
      for (final tagId in toInsert) {
        await into(
          itemTags,
        ).insert(ItemTagsCompanion.insert(itemId: itemId, tagId: tagId));
      }
    });
  }

  Future<List<LinkedVaultItemCardDto>> searchLinkableItems({
    String query = '',
    String? excludeItemId,
    int limit = 30,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    final itemsQuery = db.select(db.vaultItems).join([
      leftOuterJoin(
        db.categories,
        db.categories.id.equalsExp(db.vaultItems.categoryId),
      ),
    ]);

    itemsQuery.where(
      db.vaultItems.isDeleted.equals(false) &
          db.vaultItems.isArchived.equals(false) &
          (excludeItemId != null
              ? db.vaultItems.id.isNotValue(excludeItemId)
              : const Constant(true)),
    );

    if (normalizedQuery.isNotEmpty) {
      itemsQuery.where(
        db.vaultItems.name.lower().like('%$normalizedQuery%') |
            db.vaultItems.description.lower().like('%$normalizedQuery%'),
      );
    }

    itemsQuery.orderBy([
      OrderingTerm.desc(db.vaultItems.isPinned),
      OrderingTerm.desc(db.vaultItems.modifiedAt),
    ]);
    itemsQuery.limit(limit);

    final results = await itemsQuery.get();
    final itemIds = results
        .map((row) => row.readTable(db.vaultItems).id)
        .toList();
    final tagsMap = await _loadTagsForItems(itemIds);

    return results.map((row) {
      final item = row.readTable(db.vaultItems);
      final category = row.readTableOrNull(db.categories);

      return LinkedVaultItemCardDto(
        id: item.id,
        title: item.name,
        description: item.description,
        vaultItemType: item.type,
        isFavorite: item.isFavorite,
        isPinned: item.isPinned,
        isArchived: item.isArchived,
        isDeleted: item.isDeleted,
        usedCount: item.usedCount,
        modifiedAt: item.modifiedAt,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
                iconSource: category.iconSource,
                iconValue: category.iconValue,
              )
            : null,
        tags: tagsMap[item.id] ?? const <TagInCardDto>[],
      );
    }).toList();
  }

  Future<Map<String, List<TagInCardDto>>> _loadTagsForItems(
    List<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return {};

    final query = db.select(db.itemTags).join([
      innerJoin(db.tags, db.tags.id.equalsExp(db.itemTags.tagId)),
    ])..where(db.itemTags.itemId.isIn(itemIds));

    final results = await query.get();
    final tagsMap = <String, List<TagInCardDto>>{};

    for (final row in results) {
      final itemTag = row.readTable(db.itemTags);
      final tag = row.readTable(db.tags);

      tagsMap
          .putIfAbsent(itemTag.itemId, () => [])
          .add(TagInCardDto(id: tag.id, name: tag.name, color: tag.color));
    }

    return tagsMap;
  }
}
