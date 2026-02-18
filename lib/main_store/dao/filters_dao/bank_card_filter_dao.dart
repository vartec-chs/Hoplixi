import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/bank_card_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/bank_cards_filter.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/tables/bank_card_items.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'bank_card_filter_dao.g.dart';

@DriftAccessor(
  tables: [VaultItems, BankCardItems, Categories, Tags, ItemTags, NoteItems],
)
class BankCardFilterDao extends DatabaseAccessor<MainStore>
    with _$BankCardFilterDaoMixin
    implements FilterDao<BankCardsFilter, BankCardCardDto> {
  BankCardFilterDao(super.db);

  @override
  Future<List<BankCardCardDto>> getFiltered(BankCardsFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(bankCardItems, bankCardItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(categories, categories.id.equalsExp(vaultItems.categoryId)),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    query.orderBy(_buildOrderBy(filter));

    if (filter.base.limit != null && filter.base.limit! > 0) {
      query.limit(filter.base.limit!, offset: filter.base.offset);
    }

    final results = await query.get();

    final itemIds = results.map((row) => row.readTable(vaultItems).id).toList();
    final tagsMap = await _loadTagsForItems(itemIds);

    return results.map((row) {
      final item = row.readTable(vaultItems);
      final card = row.readTable(bankCardItems);
      final category = row.readTableOrNull(categories);

      return BankCardCardDto(
        id: item.id,
        name: item.name,
        cardholderName: card.cardholderName,
        cardNumber: card.cardNumber,
        expiryMonth: card.expiryMonth,
        expiryYear: card.expiryYear,
        cardType: card.cardType?.value,
        cardNetwork: card.cardNetwork?.value,
        bankName: card.bankName,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        isFavorite: item.isFavorite,
        isPinned: item.isPinned,
        isArchived: item.isArchived,
        isDeleted: item.isDeleted,
        usedCount: item.usedCount,
        modifiedAt: item.modifiedAt,
        tags: tagsMap[item.id] ?? [],
      );
    }).toList();
  }

  @override
  Future<int> countFiltered(BankCardsFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(bankCardItems, bankCardItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(categories, categories.id.equalsExp(vaultItems.categoryId)),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);
    query.where(_buildWhereExpression(filter));
    final results = await query.get();
    return results.length;
  }

  Expression<bool> _buildWhereExpression(BankCardsFilter filter) {
    Expression<bool> expr = const Constant(true);
    expr = expr & _applyBaseFilters(filter.base);
    expr = expr & _applyBankCardSpecificFilters(filter);
    return expr;
  }

  Expression<bool> _applyBaseFilters(BaseFilter base) {
    Expression<bool> expr = const Constant(true);

    if (base.query.isNotEmpty) {
      final q = base.query.toLowerCase();
      Expression<bool> searchExpr =
          vaultItems.name.lower().like('%$q%') |
          bankCardItems.cardholderName.lower().like('%$q%') |
          bankCardItems.bankName.lower().like('%$q%') |
          vaultItems.description.lower().like('%$q%');
      searchExpr = searchExpr | noteItems.content.lower().like('%$q%');
      expr = expr & searchExpr;
    }

    if (base.categoryIds.isNotEmpty) {
      expr = expr & vaultItems.categoryId.isIn(base.categoryIds);
    }

    if (base.tagIds.isNotEmpty) {
      final tagExists = existsQuery(
        select(itemTags)..where(
          (t) => t.itemId.equalsExp(vaultItems.id) & t.tagId.isIn(base.tagIds),
        ),
      );
      expr = expr & tagExists;
    }

    if (base.isFavorite != null) {
      expr = expr & vaultItems.isFavorite.equals(base.isFavorite!);
    }

    if (base.isPinned != null) {
      expr = expr & vaultItems.isPinned.equals(base.isPinned!);
    }

    if (base.isArchived != null) {
      expr = expr & vaultItems.isArchived.equals(base.isArchived!);
    } else {
      expr = expr & vaultItems.isArchived.equals(false);
    }

    if (base.isDeleted != null) {
      expr = expr & vaultItems.isDeleted.equals(base.isDeleted!);
    } else {
      expr = expr & vaultItems.isDeleted.equals(false);
    }

    if (base.hasNotes != null) {
      expr =
          expr &
          (base.hasNotes!
              ? vaultItems.noteId.isNotNull()
              : vaultItems.noteId.isNull());
    }

    if (base.noteIds.isNotEmpty) {
      expr = expr & vaultItems.noteId.isIn(base.noteIds);
    }

    if (base.createdAfter != null) {
      expr =
          expr & vaultItems.createdAt.isBiggerOrEqualValue(base.createdAfter!);
    }
    if (base.createdBefore != null) {
      expr =
          expr &
          vaultItems.createdAt.isSmallerOrEqualValue(base.createdBefore!);
    }
    if (base.modifiedAfter != null) {
      expr =
          expr &
          vaultItems.modifiedAt.isBiggerOrEqualValue(base.modifiedAfter!);
    }
    if (base.modifiedBefore != null) {
      expr =
          expr &
          vaultItems.modifiedAt.isSmallerOrEqualValue(base.modifiedBefore!);
    }
    if (base.lastUsedAfter != null) {
      expr =
          expr &
          vaultItems.lastUsedAt.isBiggerOrEqualValue(base.lastUsedAfter!);
    }
    if (base.lastUsedBefore != null) {
      expr =
          expr &
          vaultItems.lastUsedAt.isSmallerOrEqualValue(base.lastUsedBefore!);
    }
    if (base.minUsedCount != null) {
      expr =
          expr & vaultItems.usedCount.isBiggerOrEqualValue(base.minUsedCount!);
    }
    if (base.maxUsedCount != null) {
      expr =
          expr & vaultItems.usedCount.isSmallerOrEqualValue(base.maxUsedCount!);
    }
    return expr;
  }

  Expression<bool> _applyBankCardSpecificFilters(BankCardsFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.cardTypes.isNotEmpty) {
      Expression<bool>? typeExpr;
      for (final type in filter.cardTypes) {
        final cond = bankCardItems.cardType.equalsValue(type);
        typeExpr = typeExpr == null ? cond : (typeExpr | cond);
      }
      if (typeExpr != null) {
        expr = expr & typeExpr;
      }
    }

    if (filter.cardNetworks.isNotEmpty) {
      Expression<bool>? netExpr;
      for (final net in filter.cardNetworks) {
        final cond = bankCardItems.cardNetwork.equalsValue(net);
        netExpr = netExpr == null ? cond : (netExpr | cond);
      }
      if (netExpr != null) {
        expr = expr & netExpr;
      }
    }

    if (filter.bankName != null && filter.bankName!.isNotEmpty) {
      expr =
          expr &
          bankCardItems.bankName.lower().contains(
            filter.bankName!.toLowerCase(),
          );
    }

    if (filter.cardholderName != null && filter.cardholderName!.isNotEmpty) {
      expr =
          expr &
          bankCardItems.cardholderName.lower().contains(
            filter.cardholderName!.toLowerCase(),
          );
    }

    if (filter.hasExpiryDatePassed != null) {
      final now = DateTime.now();
      final curYear = now.year.toString();
      final curMonth = now.month.toString().padLeft(2, '0');

      if (filter.hasExpiryDatePassed!) {
        expr =
            expr &
            (bankCardItems.expiryYear.isSmallerThanValue(curYear) |
                (bankCardItems.expiryYear.equals(curYear) &
                    bankCardItems.expiryMonth.isSmallerThanValue(curMonth)));
      } else {
        expr =
            expr &
            (bankCardItems.expiryYear.isBiggerThanValue(curYear) |
                (bankCardItems.expiryYear.equals(curYear) &
                    bankCardItems.expiryMonth.isBiggerOrEqualValue(curMonth)));
      }
    }

    if (filter.isExpiringSoon != null && filter.isExpiringSoon!) {
      final now = DateTime.now();
      final fut = now.add(const Duration(days: 90));
      final futYear = fut.year.toString();
      final futMonth = fut.month.toString().padLeft(2, '0');
      final curYear = now.year.toString();
      final curMonth = now.month.toString().padLeft(2, '0');

      expr =
          expr &
          (bankCardItems.expiryYear.isBiggerThanValue(curYear) |
              (bankCardItems.expiryYear.equals(curYear) &
                  bankCardItems.expiryMonth.isBiggerOrEqualValue(curMonth))) &
          (bankCardItems.expiryYear.isSmallerThanValue(futYear) |
              (bankCardItems.expiryYear.equals(futYear) &
                  bankCardItems.expiryMonth.isSmallerOrEqualValue(futMonth)));
    }

    return expr;
  }

  Expression<double> _calculateDynamicScore(int windowDays) {
    final now = DateTime.now();
    final nowSec = now.millisecondsSinceEpoch ~/ 1000;
    final windowSec = windowDays * 24 * 60 * 60;

    return CustomExpression<double>(
      'CAST(COALESCE("vault_items"."recent_score",'
      ' 1) AS REAL) * '
      'exp(-($nowSec - COALESCE('
      '"vault_items"."last_used_at",'
      ' "vault_items"."created_at")) / '
      '$windowSec.0)',
    );
  }

  List<OrderingTerm> _buildOrderBy(BankCardsFilter filter) {
    final terms = <OrderingTerm>[];
    terms.add(
      OrderingTerm(expression: vaultItems.isPinned, mode: OrderingMode.desc),
    );

    final mode = filter.base.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    if (filter.base.isFrequentlyUsed == true) {
      final wd = filter.base.frequencyWindowDays ?? 7;
      terms.add(
        OrderingTerm(expression: _calculateDynamicScore(wd), mode: mode),
      );
      return terms;
    }

    if (filter.sortField != null) {
      switch (filter.sortField!) {
        case BankCardsSortField.name:
          terms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
        case BankCardsSortField.cardholderName:
          terms.add(
            OrderingTerm(expression: bankCardItems.cardholderName, mode: mode),
          );
        case BankCardsSortField.bankName:
          terms.add(
            OrderingTerm(expression: bankCardItems.bankName, mode: mode),
          );
        case BankCardsSortField.expiryDate:
          terms.add(
            OrderingTerm(expression: bankCardItems.expiryYear, mode: mode),
          );
          terms.add(
            OrderingTerm(expression: bankCardItems.expiryMonth, mode: mode),
          );
        case BankCardsSortField.createdAt:
          terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
        case BankCardsSortField.modifiedAt:
          terms.add(
            OrderingTerm(expression: vaultItems.modifiedAt, mode: mode),
          );
        case BankCardsSortField.lastAccessed:
          terms.add(
            OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode),
          );
      }
    } else {
      switch (filter.base.sortBy) {
        case SortBy.createdAt:
          terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
        case SortBy.modifiedAt:
          terms.add(
            OrderingTerm(expression: vaultItems.modifiedAt, mode: mode),
          );
        case SortBy.lastUsedAt:
          terms.add(
            OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode),
          );
        case SortBy.recentScore:
          final wd = filter.base.frequencyWindowDays ?? 7;
          terms.add(
            OrderingTerm(expression: _calculateDynamicScore(wd), mode: mode),
          );
      }
    }
    return terms;
  }

  Future<Map<String, List<TagInCardDto>>> _loadTagsForItems(
    List<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return {};

    final query = select(itemTags).join([
      innerJoin(tags, tags.id.equalsExp(itemTags.tagId)),
    ])..where(itemTags.itemId.isIn(itemIds));

    final results = await query.get();
    final tagsMap = <String, List<TagInCardDto>>{};

    for (final row in results) {
      final it = row.readTable(itemTags);
      final tag = row.readTable(tags);

      tagsMap.putIfAbsent(it.itemId, () => []);
      if (tagsMap[it.itemId]!.length < 10) {
        tagsMap[it.itemId]!.add(
          TagInCardDto(id: tag.id, name: tag.name, color: tag.color),
        );
      }
    }
    return tagsMap;
  }
}
