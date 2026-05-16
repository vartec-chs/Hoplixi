import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/note/note_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'note_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  NoteItems,
  Categories,
  Tags,
  ItemTags,
])
class NoteFilterDao extends DatabaseAccessor<MainStore>
    with _$NoteFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<NoteFilter, FilteredCardDto<NoteCardDto>> {
  NoteFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<NoteCardDto>>> getFiltered(
    NoteFilter filter,
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

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final note = row.readTable(noteItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = NoteCardDto(
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
        note: NoteCardDataDto(
          content: note.content,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(NoteFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(NoteFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.note);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.name != null) {
      whereExpr &= vaultItems.name.contains(filter.name!);
    }
    if (filter.contentQuery != null) {
      whereExpr &= noteItems.content.contains(filter.contentQuery!);
    }
    if (filter.hasContent != null) {
      if (filter.hasContent!) {
        whereExpr &= noteItems.content.length.isBiggerThanValue(0);
      } else {
        whereExpr &= noteItems.content.equals('');
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          noteItems.content.like(q);
      whereExpr &= textExpr;
    }

    final query = select(vaultItems).join([
      innerJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..where(whereExpr);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case NoteSortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case NoteSortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case NoteSortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case NoteSortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case NoteSortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case NoteSortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
