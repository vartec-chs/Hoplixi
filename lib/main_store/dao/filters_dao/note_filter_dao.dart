import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/note_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/notes_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'note_filter_dao.g.dart';

@DriftAccessor(tables: [VaultItems, NoteItems, Categories, Tags, ItemTags])
class NoteFilterDao extends DatabaseAccessor<MainStore>
    with _$NoteFilterDaoMixin
    implements FilterDao<NotesFilter, NoteCardDto> {
  NoteFilterDao(super.db);

  @override
  Future<List<NoteCardDto>> getFiltered(NotesFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(categories, categories.id.equalsExp(vaultItems.categoryId)),
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
      final category = row.readTableOrNull(categories);

      return NoteCardDto(
        id: item.id,
        title: item.name,
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
  Future<int> countFiltered(NotesFilter filter) async {
    final query = select(
      vaultItems,
    ).join([innerJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.id))]);
    query.where(_buildWhereExpression(filter));
    final results = await query.get();
    return results.length;
  }

  Expression<bool> _buildWhereExpression(NotesFilter filter) {
    Expression<bool> expr = const Constant(true);
    expr = expr & _applyBaseFilters(filter.base);
    expr = expr & _applyNoteSpecificFilters(filter);
    return expr;
  }

  Expression<bool> _applyBaseFilters(BaseFilter base) {
    Expression<bool> expr = const Constant(true);

    if (base.query.isNotEmpty) {
      final q = base.query.toLowerCase();
      expr =
          expr &
          (vaultItems.name.lower().like('%$q%') |
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
    } else {
      expr = expr & vaultItems.isDeleted.equals(false);
    }

    if (base.isPinned != null) {
      expr = expr & vaultItems.isPinned.equals(base.isPinned!);
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

  Expression<bool> _applyNoteSpecificFilters(NotesFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.title != null) {
      expr =
          expr &
          vaultItems.name.lower().like('%${filter.title!.toLowerCase()}%');
    }
    if (filter.content != null) {
      expr =
          expr &
          noteItems.content.lower().like('%${filter.content!.toLowerCase()}%');
    }
    if (filter.hasDescription != null) {
      expr =
          expr &
          (filter.hasDescription!
              ? vaultItems.description.isNotNull()
              : vaultItems.description.isNull());
    }
    if (filter.hasDeltaJson != null) {
      expr =
          expr &
          (filter.hasDeltaJson!
              ? noteItems.deltaJson.isNotNull()
              : noteItems.deltaJson.isNull());
    }
    if (filter.minContentLength != null) {
      expr =
          expr &
          noteItems.content.length.isBiggerOrEqualValue(
            filter.minContentLength!,
          );
    }
    if (filter.maxContentLength != null) {
      expr =
          expr &
          noteItems.content.length.isSmallerOrEqualValue(
            filter.maxContentLength!,
          );
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

  List<OrderingTerm> _buildOrderBy(NotesFilter filter) {
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
        case NotesSortField.title:
          terms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
        case NotesSortField.description:
          terms.add(
            OrderingTerm(expression: vaultItems.description, mode: mode),
          );
        case NotesSortField.contentLength:
          terms.add(
            OrderingTerm(expression: noteItems.content.length, mode: mode),
          );
        case NotesSortField.createdAt:
          terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
        case NotesSortField.modifiedAt:
          terms.add(
            OrderingTerm(expression: vaultItems.modifiedAt, mode: mode),
          );
        case NotesSortField.lastAccessed:
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
      final id = it.itemId;
      if (!tagsMap.containsKey(id)) {
        tagsMap[id] = [];
      }
      if (tagsMap[id]!.length < 10) {
        tagsMap[id]!.add(
          TagInCardDto(id: tag.id, name: tag.name, color: tag.color),
        );
      }
    }
    return tagsMap;
  }
}
