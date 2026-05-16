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
    final query = _buildQuery(filter);
    applyLimitOffset(query, filter.base);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final categoryIds =
        rows.map((r) => r.readTable(vaultItems).categoryId).whereType<String>().toList();

    final categoriesMap = await loadCategoriesForItems(categoryIds);
    final tagsMap = await loadTagsForItems(itemIds);

    final hasCardNumberExpr = db.bankCardItems.cardNumber.isNotNull();
    final hasCvvExpr = db.bankCardItems.cvv.isNotNull();

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final card = row.readTable(bankCardItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = BankCardCardDto(
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
        bankCard: BankCardCardDataDto(
          cardholderName: card.cardholderName,
          cardType: row.readWithConverter<CardType?, String>(bankCardItems.cardType),
          cardNetwork: row.readWithConverter<CardNetwork?, String>(bankCardItems.cardNetwork),
          expiryMonth: card.expiryMonth,
          expiryYear: card.expiryYear,
          bankName: card.bankName,
          hasCardNumber: row.read(hasCardNumberExpr) ?? false,
          hasCvv: row.read(hasCvvExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(BankCardFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(BankCardFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.bankCard);

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
        whereExpr &= bankCardItems.expiryMonth.isNotNull() & bankCardItems.expiryYear.isNotNull();
      } else {
        whereExpr &= bankCardItems.expiryMonth.isNull() | bankCardItems.expiryYear.isNull();
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

    final hasCardNumberExpr = db.bankCardItems.cardNumber.isNotNull();
    final hasCvvExpr = db.bankCardItems.cvv.isNotNull();

    final query = select(vaultItems).join([
      innerJoin(bankCardItems, bankCardItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..where(whereExpr)
      ..addColumns([hasCardNumberExpr, hasCvvExpr]);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case BankCardSortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case BankCardSortField.cardholderName:
          orderingTerms.add(OrderingTerm(expression: bankCardItems.cardholderName, mode: mode));
          break;
        case BankCardSortField.bankName:
          orderingTerms.add(OrderingTerm(expression: bankCardItems.bankName, mode: mode));
          break;
        case BankCardSortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case BankCardSortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case BankCardSortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case BankCardSortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case BankCardSortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
