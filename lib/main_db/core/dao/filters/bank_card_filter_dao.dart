import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/bank_card/bank_card_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'bank_card_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  BankCardItems,
  Categories,
  Tags,
  ItemTags,
])
class BankCardFilterDao extends DatabaseAccessor<MainStore>
    with _$BankCardFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<BankCardFilter, FilteredCardDto<BankCardCardDto>> {
  BankCardFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<BankCardCardDto>>> getFiltered(
    BankCardFilter filter,
  ) async {
    final whereExpr = _buildWhere(filter);
    final hasCardNumberExpr = bankCardItems.cardNumber.isNotNull();
    final hasCvvExpr = bankCardItems.cvv.isNotNull();
    final hasAccountNumberExpr = bankCardItems.accountNumber.isNotNull();
    final hasRoutingNumberExpr = bankCardItems.routingNumber.isNotNull();

    final query = selectOnly(vaultItems).join([
      innerJoin(bankCardItems, bankCardItems.itemId.equalsExp(vaultItems.id)),
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
        bankCardItems.cardholderName,
        bankCardItems.cardType,
        bankCardItems.cardNetwork,
        bankCardItems.expiryMonth,
        bankCardItems.expiryYear,
        bankCardItems.bankName,
        hasCardNumberExpr,
        hasCvvExpr,
        hasAccountNumberExpr,
        hasRoutingNumberExpr,
      ])
      ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case BankCardSortField.name:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case BankCardSortField.cardholderName:
          orderingTerms.add(
              OrderingTerm(expression: bankCardItems.cardholderName, mode: mode));
          break;
        case BankCardSortField.bankName:
          orderingTerms.add(
              OrderingTerm(expression: bankCardItems.bankName, mode: mode));
          break;
        case BankCardSortField.createdAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case BankCardSortField.modifiedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case BankCardSortField.lastUsedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case BankCardSortField.usedCount:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case BankCardSortField.recentScore:
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

      final cardDto = BankCardCardDto(
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
        bankCard: BankCardCardDataDto(
          cardholderName: row.read(bankCardItems.cardholderName),
          cardType:
              row.readWithConverter<CardType?, String>(bankCardItems.cardType),
          cardNetwork: row.readWithConverter<CardNetwork?, String>(
              bankCardItems.cardNetwork),
          expiryMonth: row.read(bankCardItems.expiryMonth),
          expiryYear: row.read(bankCardItems.expiryYear),
          bankName: row.read(bankCardItems.bankName),
          hasCardNumber: row.read(hasCardNumberExpr) ?? false,
          hasCvv: row.read(hasCvvExpr) ?? false,
          hasAccountNumber: row.read(hasAccountNumberExpr) ?? false,
          hasRoutingNumber: row.read(hasRoutingNumberExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(BankCardFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query = selectOnly(vaultItems).join([
      innerJoin(bankCardItems, bankCardItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..addColumns([countExp])
      ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(BankCardFilter filter) {
    Expression<bool> whereExpr =
        vaultItems.type.equalsValue(VaultItemType.bankCard);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.cardholderName != null) {
      whereExpr &= bankCardItems.cardholderName.contains(filter.cardholderName!);
    }
    if (filter.cardType != null) {
      whereExpr &= bankCardItems.cardType.equalsValue(filter.cardType!);
    }
    if (filter.cardNetwork != null) {
      whereExpr &= bankCardItems.cardNetwork.equalsValue(filter.cardNetwork!);
    }
    if (filter.bankName != null) {
      whereExpr &= bankCardItems.bankName.contains(filter.bankName!);
    }
    if (filter.hasExpiry != null) {
      if (filter.hasExpiry!) {
        whereExpr &= bankCardItems.expiryMonth.isNotNull() &
            bankCardItems.expiryYear.isNotNull();
      } else {
        whereExpr &=
            bankCardItems.expiryMonth.isNull() | bankCardItems.expiryYear.isNull();
      }
    }
    if (filter.hasCvv != null) {
      if (filter.hasCvv!) {
        whereExpr &= bankCardItems.cvv.isNotNull();
      } else {
        whereExpr &= bankCardItems.cvv.isNull();
      }
    }
    if (filter.hasAccountNumber != null) {
      if (filter.hasAccountNumber!) {
        whereExpr &= bankCardItems.accountNumber.isNotNull();
      } else {
        whereExpr &= bankCardItems.accountNumber.isNull();
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          bankCardItems.cardholderName.like(q) |
          bankCardItems.bankName.like(q);
      whereExpr &= textExpr;
    }

    return whereExpr;
  }
}
