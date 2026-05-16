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
    final whereExpr = _buildWhere(filter);

    final query = selectOnly(vaultItems).join([
      innerJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.id)),
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
        noteItems.content,
      ])
      ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case NoteSortField.name:
          orderingTerms
              .add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case NoteSortField.createdAt:
          orderingTerms
              .add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case NoteSortField.modifiedAt:
          orderingTerms
              .add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case NoteSortField.lastUsedAt:
          orderingTerms
              .add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case NoteSortField.usedCount:
          orderingTerms
              .add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case NoteSortField.recentScore:
          orderingTerms
              .add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
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

      final cardDto = NoteCardDto(
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
        note: NoteCardDataDto(
          content: row.read(noteItems.content)!,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(NoteFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query = selectOnly(vaultItems).join([
      innerJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..addColumns([countExp])
      ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(NoteFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.note);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.name != null) {
      whereExpr &= vaultItems.name.contains(filter.name!);
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          noteItems.content.like(q);
      whereExpr &= textExpr;
    }

    return whereExpr;
  }
}
