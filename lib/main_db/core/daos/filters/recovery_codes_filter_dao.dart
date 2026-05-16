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

@DriftAccessor(
  tables: [VaultItems, RecoveryCodesItems, Categories, Tags, ItemTags],
)
class RecoveryCodesFilterDao extends DatabaseAccessor<MainStore>
    with _$RecoveryCodesFilterDaoMixin, BaseFilterQueryMixin
    implements
        FilterDao<RecoveryCodesFilter, FilteredCardDto<RecoveryCodesCardDto>> {
  RecoveryCodesFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<RecoveryCodesCardDto>>> getFiltered(
    RecoveryCodesFilter filter,
  ) async {
    final whereExpr = _buildWhere(filter);
    final hasCodesExpr = db.recoveryCodesItems.codesCount.isBiggerThanValue(0);

    final query =
        selectOnly(vaultItems).join([
            innerJoin(
              recoveryCodesItems,
              recoveryCodesItems.itemId.equalsExp(vaultItems.id),
            ),
          ])
          ..addColumns([
            vaultItems.id,
            vaultItems.type,
            vaultItems.name,
            vaultItems.description,
            vaultItems.categoryId,
            vaultItems.iconRefId,
            vaultItems.isFavorite,
            vaultItems.isArchived,
            vaultItems.isPinned,
            vaultItems.isDeleted,
            vaultItems.createdAt,
            vaultItems.modifiedAt,
            vaultItems.lastUsedAt,
            vaultItems.archivedAt,
            vaultItems.deletedAt,
            vaultItems.recentScore,
            recoveryCodesItems.codesCount,
            recoveryCodesItems.usedCount,
            recoveryCodesItems.generatedAt,
            recoveryCodesItems.oneTime,
            hasCodesExpr,
          ])
          ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case RecoveryCodesSortField.name:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.name, mode: mode),
          );
          break;
        case RecoveryCodesSortField.generatedAt:
          orderingTerms.add(
            OrderingTerm(
              expression: recoveryCodesItems.generatedAt,
              mode: mode,
            ),
          );
          break;
        case RecoveryCodesSortField.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.createdAt, mode: mode),
          );
          break;
        case RecoveryCodesSortField.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.modifiedAt, mode: mode),
          );
          break;
        case RecoveryCodesSortField.lastUsedAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode),
          );
          break;
        case RecoveryCodesSortField.usedCount:
          orderingTerms.add(
            OrderingTerm(expression: recoveryCodesItems.usedCount, mode: mode),
          );
          break;
        case RecoveryCodesSortField.recentScore:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.recentScore, mode: mode),
          );
          break;
      }
    }
    query.orderBy(orderingTerms);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final itemIds = rows.map((r) => r.read(vaultItems.id)!).toList();
    final categoryIds = rows
        .map((r) => r.read(vaultItems.categoryId))
        .whereType<String>()
        .toList();

    final categoriesMap = await loadCategoriesForItems(categoryIds);
    final tagsMap = await loadTagsForItems(itemIds);

    return rows.map((row) {
      final itemId = row.read(vaultItems.id)!;
      final categoryId = row.read(vaultItems.categoryId);
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[itemId] ?? const [],
      );

      final cardDto = RecoveryCodesCardDto(
        item: VaultItemCardDto(
          itemId: itemId,
          type: row.readWithConverter<VaultItemType, String>(vaultItems.type)!,
          name: row.read(vaultItems.name)!,
          description: row.read(vaultItems.description),
          categoryId: categoryId,
          iconRefId: row.read(vaultItems.iconRefId),
          isFavorite: row.read(vaultItems.isFavorite)!,
          isArchived: row.read(vaultItems.isArchived)!,
          isPinned: row.read(vaultItems.isPinned)!,
          isDeleted: row.read(vaultItems.isDeleted)!,
          createdAt: row.read(vaultItems.createdAt)!,
          modifiedAt: row.read(vaultItems.modifiedAt)!,
          lastUsedAt: row.read(vaultItems.lastUsedAt),
          archivedAt: row.read(vaultItems.archivedAt),
          deletedAt: row.read(vaultItems.deletedAt),
          recentScore: row.read(vaultItems.recentScore),
        ),
        recoveryCodes: RecoveryCodesCardDataDto(
          codesCount: row.read(recoveryCodesItems.codesCount)!,
          usedCount: row.read(recoveryCodesItems.usedCount)!,
          generatedAt: row.read(recoveryCodesItems.generatedAt),
          oneTime: row.read(recoveryCodesItems.oneTime) ?? false,
          hasCodes: row.read(hasCodesExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(RecoveryCodesFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query =
        selectOnly(vaultItems).join([
            innerJoin(
              recoveryCodesItems,
              recoveryCodesItems.itemId.equalsExp(vaultItems.id),
            ),
          ])
          ..addColumns([countExp])
          ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(RecoveryCodesFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(
      VaultItemType.recoveryCodes,
    );

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.generatedAfter != null) {
      whereExpr &= recoveryCodesItems.generatedAt.isBiggerOrEqualValue(
        filter.generatedAfter!,
      );
    }
    if (filter.generatedBefore != null) {
      whereExpr &= recoveryCodesItems.generatedAt.isSmallerOrEqualValue(
        filter.generatedBefore!,
      );
    }
    if (filter.oneTime != null) {
      whereExpr &= recoveryCodesItems.oneTime.equals(filter.oneTime!);
    }

    if (filter.minCodesCount != null) {
      whereExpr &= recoveryCodesItems.codesCount.isBiggerOrEqualValue(
        filter.minCodesCount!,
      );
    }
    if (filter.maxCodesCount != null) {
      whereExpr &= recoveryCodesItems.codesCount.isSmallerOrEqualValue(
        filter.maxCodesCount!,
      );
    }
    if (filter.minUsedCount != null) {
      whereExpr &= recoveryCodesItems.usedCount.isBiggerOrEqualValue(
        filter.minUsedCount!,
      );
    }
    if (filter.maxUsedCount != null) {
      whereExpr &= recoveryCodesItems.usedCount.isSmallerOrEqualValue(
        filter.maxUsedCount!,
      );
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
      final textExpr = vaultItems.name.like(q) | vaultItems.description.like(q);
      whereExpr &= textExpr;
    }

    return whereExpr;
  }
}
