import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/otp_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/otps_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/otp_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'otp_filter_dao.g.dart';

@DriftAccessor(
  tables: [VaultItems, OtpItems, Categories, Tags, ItemTags, NoteItems],
)
class OtpFilterDao extends DatabaseAccessor<MainStore>
    with _$OtpFilterDaoMixin
    implements FilterDao<OtpsFilter, OtpCardDto> {
  OtpFilterDao(super.db);

  @override
  Future<List<OtpCardDto>> getFiltered(OtpsFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(otpItems, otpItems.itemId.equalsExp(vaultItems.id)),
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
      final otp = row.readTable(otpItems);
      final category = row.readTableOrNull(categories);

      return OtpCardDto(
        id: item.id,
        issuer: otp.issuer,
        accountName: otp.accountName,
        type: otp.type.name,
        digits: otp.digits,
        period: otp.period,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        tags: tagsMap[item.id] ?? [],
        isFavorite: item.isFavorite,
        isPinned: item.isPinned,
        isArchived: item.isArchived,
        isDeleted: item.isDeleted,
        usedCount: item.usedCount,
        modifiedAt: item.modifiedAt,
      );
    }).toList();
  }

  @override
  Future<int> countFiltered(OtpsFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(otpItems, otpItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(categories, categories.id.equalsExp(vaultItems.categoryId)),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);
    query.where(_buildWhereExpression(filter));
    final results = await query.get();
    return results.length;
  }

  Expression<bool> _buildWhereExpression(OtpsFilter filter) {
    Expression<bool> expr = const Constant(true);
    expr = expr & _applyBaseFilters(filter.base);
    expr = expr & _applyOtpSpecificFilters(filter);
    return expr;
  }

  Expression<bool> _applyBaseFilters(BaseFilter base) {
    Expression<bool> expr = const Constant(true);

    if (base.query.isNotEmpty) {
      final q = base.query.toLowerCase();
      Expression<bool> searchExpr =
          otpItems.issuer.lower().like('%$q%') |
          otpItems.accountName.lower().like('%$q%');
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

    if (base.isPinned != null) {
      expr = expr & vaultItems.isPinned.equals(base.isPinned!);
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

  Expression<bool> _applyOtpSpecificFilters(OtpsFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.types.isNotEmpty) {
      final typeExprs = filter.types
          .map((type) => otpItems.type.equals(type.name))
          .reduce((a, b) => a | b);
      expr = expr & typeExprs;
    }

    if (filter.algorithms.isNotEmpty) {
      final algExprs = filter.algorithms
          .map((alg) => otpItems.algorithm.equals(alg.name))
          .reduce((a, b) => a | b);
      expr = expr & algExprs;
    }

    if (filter.issuer != null) {
      expr =
          expr &
          otpItems.issuer.lower().like('%${filter.issuer!.toLowerCase()}%');
    }
    if (filter.accountName != null) {
      expr =
          expr &
          otpItems.accountName.lower().like(
            '%${filter.accountName!.toLowerCase()}%',
          );
    }
    if (filter.digits.isNotEmpty) {
      expr = expr & otpItems.digits.isIn(filter.digits);
    }
    if (filter.periods.isNotEmpty) {
      expr = expr & otpItems.period.isIn(filter.periods);
    }
    if (filter.secretEncodings.isNotEmpty) {
      final encExprs = filter.secretEncodings
          .map((enc) => otpItems.secretEncoding.equals(enc.name))
          .reduce((a, b) => a | b);
      expr = expr & encExprs;
    }
    if (filter.hasPasswordLink != null) {
      expr =
          expr &
          (filter.hasPasswordLink!
              ? otpItems.passwordItemId.isNotNull()
              : otpItems.passwordItemId.isNull());
    }
    if (filter.hasNotes != null) {
      expr =
          expr &
          (filter.hasNotes!
              ? vaultItems.noteId.isNotNull()
              : vaultItems.noteId.isNull());
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

  List<OrderingTerm> _buildOrderBy(OtpsFilter filter) {
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
        case OtpsSortField.issuer:
          terms.add(OrderingTerm(expression: otpItems.issuer, mode: mode));
        case OtpsSortField.accountName:
          terms.add(OrderingTerm(expression: otpItems.accountName, mode: mode));
        case OtpsSortField.type:
          terms.add(OrderingTerm(expression: otpItems.type, mode: mode));
        case OtpsSortField.algorithm:
          terms.add(OrderingTerm(expression: otpItems.algorithm, mode: mode));
        case OtpsSortField.digits:
          terms.add(OrderingTerm(expression: otpItems.digits, mode: mode));
        case OtpsSortField.period:
          terms.add(OrderingTerm(expression: otpItems.period, mode: mode));
        case OtpsSortField.createdAt:
          terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
        case OtpsSortField.modifiedAt:
          terms.add(
            OrderingTerm(expression: vaultItems.modifiedAt, mode: mode),
          );
        case OtpsSortField.lastAccessed:
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
