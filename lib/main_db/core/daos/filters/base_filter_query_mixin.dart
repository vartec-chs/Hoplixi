import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/filter_meta_dto.dart';

import '../../main_store.dart';
import '../../models/filters/filters.dart';

mixin BaseFilterQueryMixin on DatabaseAccessor<MainStore> {
  /// Builds a map of category IDs to category DTOs for the given items.
  Future<Map<String, CategoryInCardDto>> loadCategoriesForItems(
    List<String> categoryIds,
  ) async {
    if (categoryIds.isEmpty) return {};

    final uniqueIds = categoryIds.toSet().toList();
    final categories = await (select(
      db.categories,
    )..where((t) => t.id.isIn(uniqueIds))).get();

    return {
      for (final c in categories)
        c.id: CategoryInCardDto(
          id: c.id,
          name: c.name,
          color: c.color,
          iconRefId: c.iconRefId,
        ),
    };
  }

  /// Builds a map of item IDs to their first N tags.
  Future<Map<String, List<TagInCardDto>>> loadTagsForItems(
    List<String> itemIds, {
    int maxTagsPerItem = 10,
  }) async {
    if (itemIds.isEmpty) return {};

    // Group concat or window functions are complex in Drift without raw SQL.
    // Assuming tags are light, we fetch all tags for these items and group in Dart.
    // If an item has >10 tags, we'll slice it in Dart.
    final query = select(db.itemTags).join([
      innerJoin(db.tags, db.tags.id.equalsExp(db.itemTags.tagId)),
    ])..where(db.itemTags.itemId.isIn(itemIds));

    final rows = await query.get();

    final map = <String, List<TagInCardDto>>{};
    for (final row in rows) {
      final itemId = row.readTable(db.itemTags).itemId;
      final tag = row.readTable(db.tags);

      final tagDto = TagInCardDto(id: tag.id, name: tag.name, color: tag.color);

      map.putIfAbsent(itemId, () => []).add(tagDto);
    }

    // Limit to maxTagsPerItem
    for (final entry in map.entries) {
      if (entry.value.length > maxTagsPerItem) {
        map[entry.key] = entry.value.take(maxTagsPerItem).toList();
      }
    }

    return map;
  }

  /// Applies limit and offset to a joined select statement.
  void applyLimitOffset(
    JoinedSelectStatement<HasResultSet, dynamic> query,
    BaseFilter base,
  ) {
    if (base.limit != null && base.limit! > 0) {
      query.limit(base.limit!, offset: base.offset);
    }
  }

  /// Base expression for filtering common vault item fields.
  Expression<bool> applyBaseVaultItemFilters(BaseFilter base) {
    Expression<bool> expr = const Constant(true);

    if (base.isDeleted != null) {
      expr &= db.vaultItems.isDeleted.equals(base.isDeleted!);
    } else {
      expr &= db.vaultItems.isDeleted.equals(false);
    }

    if (base.isArchived != null) {
      expr &= db.vaultItems.isArchived.equals(base.isArchived!);
    } else {
      expr &= db.vaultItems.isArchived.equals(false);
    }

    if (base.isFavorite != null) {
      expr &= db.vaultItems.isFavorite.equals(base.isFavorite!);
    }
    if (base.isPinned != null) {
      expr &= db.vaultItems.isPinned.equals(base.isPinned!);
    }

    if (base.createdAfter != null) {
      expr &= db.vaultItems.createdAt.isBiggerOrEqualValue(base.createdAfter!);
    }
    if (base.createdBefore != null) {
      expr &= db.vaultItems.createdAt.isSmallerOrEqualValue(
        base.createdBefore!,
      );
    }

    if (base.modifiedAfter != null) {
      expr &= db.vaultItems.modifiedAt.isBiggerOrEqualValue(
        base.modifiedAfter!,
      );
    }
    if (base.modifiedBefore != null) {
      expr &= db.vaultItems.modifiedAt.isSmallerOrEqualValue(
        base.modifiedBefore!,
      );
    }

    if (base.lastUsedAfter != null) {
      expr &= db.vaultItems.lastUsedAt.isBiggerOrEqualValue(
        base.lastUsedAfter!,
      );
    }
    if (base.lastUsedBefore != null) {
      expr &= db.vaultItems.lastUsedAt.isSmallerOrEqualValue(
        base.lastUsedBefore!,
      );
    }

    if (base.minUsedCount != null) {
      expr &= db.vaultItems.usedCount.isBiggerOrEqualValue(base.minUsedCount!);
    }
    if (base.maxUsedCount != null) {
      expr &= db.vaultItems.usedCount.isSmallerOrEqualValue(base.maxUsedCount!);
    }

    if (base.isFrequentlyUsed != null && base.isFrequentlyUsed!) {
      if (base.frequencyWindowDays != null) {
        final cutoff = DateTime.now().subtract(
          Duration(days: base.frequencyWindowDays!),
        );
        expr &= db.vaultItems.lastUsedAt.isBiggerOrEqualValue(cutoff);
      }
      expr &= db.vaultItems.recentScore.isBiggerThanValue(0.0);
    }

    if (base.categoryIds.isNotEmpty) {
      expr &= db.vaultItems.categoryId.isIn(base.categoryIds);
    }

    if (base.tagIds.isNotEmpty) {
      // Ищем элементы, которые имеют хотя бы один из указанных тегов
      final subquery = selectOnly(db.itemTags)
        ..addColumns([db.itemTags.itemId])
        ..where(db.itemTags.tagId.isIn(base.tagIds));

      expr &= db.vaultItems.id.isInQuery(subquery);
    }

    return expr;
  }

  /// Builds base ordering terms. Pinned items always come first.
  List<OrderingTerm> buildBaseOrdering(BaseFilter base) {
    final terms = <OrderingTerm>[];

    // Pinned always first
    terms.add(
      OrderingTerm(expression: db.vaultItems.isPinned, mode: OrderingMode.desc),
    );

    final isAsc = base.sortDirection == SortDirection.asc;
    final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;

    switch (base.sortBy) {
      case BaseSortBy.name:
        terms.add(OrderingTerm(expression: db.vaultItems.name, mode: mode));
        break;
      case BaseSortBy.createdAt:
        terms.add(
          OrderingTerm(expression: db.vaultItems.createdAt, mode: mode),
        );
        break;
      case BaseSortBy.modifiedAt:
        terms.add(
          OrderingTerm(expression: db.vaultItems.modifiedAt, mode: mode),
        );
        break;
      case BaseSortBy.lastUsedAt:
        terms.add(
          OrderingTerm(expression: db.vaultItems.lastUsedAt, mode: mode),
        );
        break;
      case BaseSortBy.recentScore:
        terms.add(
          OrderingTerm(expression: db.vaultItems.recentScore, mode: mode),
        );
        break;
      case BaseSortBy.usedCount:
        terms.add(
          OrderingTerm(expression: db.vaultItems.usedCount, mode: mode),
        );
        break;
    }

    return terms;
  }
}
