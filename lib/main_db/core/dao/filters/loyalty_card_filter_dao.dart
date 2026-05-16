import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/loyalty_card/loyalty_card_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'loyalty_card_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  LoyaltyCardItems,
  Categories,
  Tags,
  ItemTags,
])
class LoyaltyCardFilterDao extends DatabaseAccessor<MainStore>
    with _$LoyaltyCardFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<LoyaltyCardFilter, FilteredCardDto<LoyaltyCardCardDto>> {
  LoyaltyCardFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<LoyaltyCardCardDto>>> getFiltered(
    LoyaltyCardFilter filter,
  ) async {
    final whereExpr = _buildWhere(filter);
    final hasCardNumberExpr = loyaltyCardItems.cardNumber.isNotNull();
    final hasBarcodeValueExpr = loyaltyCardItems.barcodeValue.isNotNull();
    final hasPasswordExpr = loyaltyCardItems.password.isNotNull();

    final query = selectOnly(vaultItems).join([
      innerJoin(
          loyaltyCardItems, loyaltyCardItems.itemId.equalsExp(vaultItems.id)),
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
        loyaltyCardItems.programName,
        loyaltyCardItems.barcodeType,
        loyaltyCardItems.issuer,
        loyaltyCardItems.website,
        loyaltyCardItems.phone,
        loyaltyCardItems.email,
        loyaltyCardItems.validFrom,
        loyaltyCardItems.validTo,
        hasCardNumberExpr,
        hasBarcodeValueExpr,
        hasPasswordExpr,
      ])
      ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case LoyaltyCardSortField.name:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case LoyaltyCardSortField.programName:
          orderingTerms.add(OrderingTerm(
              expression: loyaltyCardItems.programName, mode: mode));
          break;
        case LoyaltyCardSortField.issuer:
          orderingTerms.add(
              OrderingTerm(expression: loyaltyCardItems.issuer, mode: mode));
          break;
        case LoyaltyCardSortField.validTo:
          orderingTerms.add(
              OrderingTerm(expression: loyaltyCardItems.validTo, mode: mode));
          break;
        case LoyaltyCardSortField.createdAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case LoyaltyCardSortField.modifiedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case LoyaltyCardSortField.lastUsedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case LoyaltyCardSortField.usedCount:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case LoyaltyCardSortField.recentScore:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.recentScore, mode: mode));
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

      final cardDto = LoyaltyCardCardDto(
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
        loyaltyCard: LoyaltyCardCardDataDto(
          programName: row.read(loyaltyCardItems.programName)!,
          barcodeType: row.readWithConverter<LoyaltyBarcodeType?, String>(
              loyaltyCardItems.barcodeType),
          issuer: row.read(loyaltyCardItems.issuer),
          website: row.read(loyaltyCardItems.website),
          phone: row.read(loyaltyCardItems.phone),
          email: row.read(loyaltyCardItems.email),
          validFrom: row.read(loyaltyCardItems.validFrom),
          validTo: row.read(loyaltyCardItems.validTo),
          hasCardNumber: row.read(hasCardNumberExpr) ?? false,
          hasBarcodeValue: row.read(hasBarcodeValueExpr) ?? false,
          hasPassword: row.read(hasPasswordExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(LoyaltyCardFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query = selectOnly(vaultItems).join([
      innerJoin(
          loyaltyCardItems, loyaltyCardItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..addColumns([countExp])
      ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(LoyaltyCardFilter filter) {
    Expression<bool> whereExpr =
        vaultItems.type.equalsValue(VaultItemType.loyaltyCard);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.programName != null) {
      whereExpr &= loyaltyCardItems.programName.contains(filter.programName!);
    }
    if (filter.barcodeType != null) {
      whereExpr &=
          loyaltyCardItems.barcodeType.equalsValue(filter.barcodeType!);
    }
    if (filter.issuer != null) {
      whereExpr &= loyaltyCardItems.issuer.contains(filter.issuer!);
    }
    if (filter.website != null) {
      whereExpr &= loyaltyCardItems.website.contains(filter.website!);
    }
    if (filter.phone != null) {
      whereExpr &= loyaltyCardItems.phone.contains(filter.phone!);
    }
    if (filter.email != null) {
      whereExpr &= loyaltyCardItems.email.contains(filter.email!);
    }

    if (filter.validFromAfter != null) {
      whereExpr &= loyaltyCardItems.validFrom
          .isBiggerOrEqualValue(filter.validFromAfter!);
    }
    if (filter.validToBefore != null) {
      whereExpr &=
          loyaltyCardItems.validTo.isSmallerOrEqualValue(filter.validToBefore!);
    }

    if (filter.hasCardNumber != null) {
      if (filter.hasCardNumber!) {
        whereExpr &= loyaltyCardItems.cardNumber.isNotNull();
      } else {
        whereExpr &= loyaltyCardItems.cardNumber.isNull();
      }
    }
    if (filter.hasBarcodeValue != null) {
      if (filter.hasBarcodeValue!) {
        whereExpr &= loyaltyCardItems.barcodeValue.isNotNull();
      } else {
        whereExpr &= loyaltyCardItems.barcodeValue.isNull();
      }
    }
    if (filter.hasPassword != null) {
      if (filter.hasPassword!) {
        whereExpr &= loyaltyCardItems.password.isNotNull();
      } else {
        whereExpr &= loyaltyCardItems.password.isNull();
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          loyaltyCardItems.programName.like(q) |
          loyaltyCardItems.issuer.like(q) |
          loyaltyCardItems.website.like(q);
      whereExpr &= textExpr;
    }

    return whereExpr;
  }
}
