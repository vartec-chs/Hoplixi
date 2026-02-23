import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/recovery_codes_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/recovery_codes_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/recovery_codes_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'recovery_codes_filter_dao.g.dart';

@DriftAccessor(
  tables: [
    VaultItems,
    RecoveryCodesItems,
    Categories,
    Tags,
    ItemTags,
    NoteItems,
  ],
)
class RecoveryCodesFilterDao extends DatabaseAccessor<MainStore>
    with _$RecoveryCodesFilterDaoMixin
    implements FilterDao<RecoveryCodesFilter, RecoveryCodesCardDto> {
  RecoveryCodesFilterDao(super.db);

  @override
  Future<List<RecoveryCodesCardDto>> getFiltered(
    RecoveryCodesFilter filter,
  ) async {
    final query = select(vaultItems).join([
      innerJoin(
        recoveryCodesItems,
        recoveryCodesItems.itemId.equalsExp(vaultItems.id),
      ),
      leftOuterJoin(categories, categories.id.equalsExp(vaultItems.categoryId)),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    query.orderBy(_buildOrderBy(filter));

    if (filter.base.limit != null && filter.base.limit! > 0) {
      query.limit(filter.base.limit!, offset: filter.base.offset);
    }

    final rows = await query.get();
    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final tagsMap = await _loadTagsForItems(itemIds);

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final data = row.readTable(recoveryCodesItems);
      final category = row.readTableOrNull(categories);

      return RecoveryCodesCardDto(
        id: item.id,
        name: item.name,
        codesCount: data.codesCount,
        codesUsedCount: data.usedCount,
        oneTime: data.oneTime,
        generatedAt: data.generatedAt,
        displayHint: data.displayHint,
        description: item.description,
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
        usedCountMetric: item.usedCount,
        modifiedAt: item.modifiedAt,
        createdAt: item.createdAt,
      );
    }).toList();
  }

  @override
  Future<int> countFiltered(RecoveryCodesFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(
        recoveryCodesItems,
        recoveryCodesItems.itemId.equalsExp(vaultItems.id),
      ),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    final rows = await query.get();
    return rows.length;
  }

  Expression<bool> _buildWhereExpression(RecoveryCodesFilter filter) {
    Expression<bool> expr = const Constant(true);
    expr = expr & _applyBaseFilters(filter.base);
    expr = expr & _applySpecificFilters(filter);
    return expr;
  }

  Expression<bool> _applyBaseFilters(BaseFilter base) {
    Expression<bool> expr = const Constant(true);

    if (base.isDeleted == null) {
      expr = expr & vaultItems.isDeleted.equals(false);
    }

    if (base.query.isNotEmpty) {
      final q = base.query.toLowerCase();
      expr =
          expr &
          (vaultItems.name.lower().like('%$q%') |
              recoveryCodesItems.displayHint.lower().like('%$q%') |
              vaultItems.description.lower().like('%$q%') |
              noteItems.content.lower().like('%$q%'));
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
    }

    return expr;
  }

  Expression<bool> _applySpecificFilters(RecoveryCodesFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.name != null) {
      expr =
          expr &
          vaultItems.name.lower().like('%${filter.name!.toLowerCase()}%');
    }

    if (filter.displayHint != null) {
      expr =
          expr &
          recoveryCodesItems.displayHint.lower().like(
            '%${filter.displayHint!.toLowerCase()}%',
          );
    }

    if (filter.oneTime != null) {
      expr = expr & recoveryCodesItems.oneTime.equals(filter.oneTime!);
    }

    if (filter.depletedOnly == true) {
      expr =
          expr &
          recoveryCodesItems.codesCount.isNotNull() &
          recoveryCodesItems.usedCount.isNotNull() &
          recoveryCodesItems.usedCount.isBiggerOrEqual(
            recoveryCodesItems.codesCount,
          );
    }

    return expr;
  }

  List<OrderingTerm> _buildOrderBy(RecoveryCodesFilter filter) {
    final terms = <OrderingTerm>[
      OrderingTerm(expression: vaultItems.isPinned, mode: OrderingMode.desc),
    ];

    final mode = filter.base.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    switch (filter.sortField) {
      case RecoveryCodesSortField.name:
        terms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
      case RecoveryCodesSortField.codesCount:
        terms.add(
          OrderingTerm(expression: recoveryCodesItems.codesCount, mode: mode),
        );
      case RecoveryCodesSortField.usedCount:
        terms.add(
          OrderingTerm(expression: recoveryCodesItems.usedCount, mode: mode),
        );
      case RecoveryCodesSortField.generatedAt:
        terms.add(
          OrderingTerm(expression: recoveryCodesItems.generatedAt, mode: mode),
        );
      case RecoveryCodesSortField.createdAt:
        terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
      case RecoveryCodesSortField.modifiedAt:
        terms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
      case RecoveryCodesSortField.lastAccessed:
        terms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
      case null:
        terms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
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

    final rows = await query.get();
    final tagsMap = <String, List<TagInCardDto>>{};

    for (final row in rows) {
      final it = row.readTable(itemTags);
      final tag = row.readTable(tags);
      final list = tagsMap.putIfAbsent(it.itemId, () => []);
      if (list.length < 10) {
        list.add(TagInCardDto(id: tag.id, name: tag.name, color: tag.color));
      }
    }

    return tagsMap;
  }
}
