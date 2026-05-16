import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/recovery_codes/recovery_codes_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'recovery_codes_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  RecoveryCodesItems,
  Categories,
  Tags,
  ItemTags,
])
class RecoveryCodesFilterDao extends DatabaseAccessor<MainStore>
    with _$RecoveryCodesFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<RecoveryCodesFilter, FilteredCardDto<RecoveryCodesCardDto>> {
  RecoveryCodesFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<RecoveryCodesCardDto>>> getFiltered(
    RecoveryCodesFilter filter,
  ) async {
    final query = _buildQuery(filter);
    applyLimitOffset(query, filter.base);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final categoryIds =
        rows.map((r) => r.readTable(vaultItems).categoryId).whereType<String>().toList();

    final categoriesMap = await loadCategoriesForItems(categoryIds);
    final tagsMap = await loadTagsForItems(itemIds);

    final hasCodesExpr = db.recoveryCodesItems.codesCount.isBiggerThanValue(0);

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final rc = row.readTable(recoveryCodesItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = RecoveryCodesCardDto(
        item: VaultItemCardDto(
          itemId: item.id,
          type: item.type,
          name: item.name,
          description: item.description,
          categoryId: item.categoryId,
          iconRefId: item.iconRefId,
          isFavorite: item.isFavorite,
          isArchived: item.isArchived,
          isPinned: item.isPinned,
          isDeleted: item.isDeleted,
          createdAt: item.createdAt,
          modifiedAt: item.modifiedAt,
          lastUsedAt: item.lastUsedAt,
          archivedAt: item.archivedAt,
          deletedAt: item.deletedAt,
          recentScore: item.recentScore,
        ),
        recoveryCodes: RecoveryCodesCardDataDto(
          codesCount: rc.codesCount,
          usedCount: rc.usedCount,
          generatedAt: rc.generatedAt,
          oneTime: rc.oneTime,
          hasCodes: row.read(hasCodesExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(RecoveryCodesFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(RecoveryCodesFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.recoveryCodes);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.generatedAfter != null) {
      whereExpr &= recoveryCodesItems.generatedAt.isBiggerOrEqualValue(filter.generatedAfter!);
    }
    if (filter.generatedBefore != null) {
      whereExpr &= recoveryCodesItems.generatedAt.isSmallerOrEqualValue(filter.generatedBefore!);
    }
    if (filter.oneTime != null) {
      whereExpr &= recoveryCodesItems.oneTime.equals(filter.oneTime!);
    }

    if (filter.minCodesCount != null) {
      whereExpr &= recoveryCodesItems.codesCount.isBiggerOrEqualValue(filter.minCodesCount!);
    }
    if (filter.maxCodesCount != null) {
      whereExpr &= recoveryCodesItems.codesCount.isSmallerOrEqualValue(filter.maxCodesCount!);
    }
    if (filter.minUsedCount != null) {
      whereExpr &= recoveryCodesItems.usedCount.isBiggerOrEqualValue(filter.minUsedCount!);
    }
    if (filter.maxUsedCount != null) {
      whereExpr &= recoveryCodesItems.usedCount.isSmallerOrEqualValue(filter.maxUsedCount!);
    }

    if (filter.hasCodes != null) {
      if (filter.hasCodes!) {
        whereExpr &= recoveryCodesItems.codesCount.isBiggerThanValue(0);
      } else {
        whereExpr &= recoveryCodesItems.codesCount.equals(0);
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q);
      whereExpr &= textExpr;
    }

    final hasCodesExpr = db.recoveryCodesItems.codesCount.isBiggerThanValue(0);

    final query = select(vaultItems).join([
      innerJoin(recoveryCodesItems, recoveryCodesItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..where(whereExpr)
      ..addColumns([hasCodesExpr]);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case RecoveryCodesSortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case RecoveryCodesSortField.generatedAt:
          orderingTerms.add(OrderingTerm(expression: recoveryCodesItems.generatedAt, mode: mode));
          break;
        case RecoveryCodesSortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case RecoveryCodesSortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case RecoveryCodesSortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case RecoveryCodesSortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case RecoveryCodesSortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
