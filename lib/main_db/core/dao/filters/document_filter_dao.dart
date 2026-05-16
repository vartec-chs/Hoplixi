import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/document/document_items.dart';
import '../../tables/document/document_versions.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'document_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  DocumentItems,
  DocumentVersions,
  Categories,
  Tags,
  ItemTags,
])
class DocumentFilterDao extends DatabaseAccessor<MainStore>
    with _$DocumentFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<DocumentFilter, FilteredCardDto<DocumentCardDto>> {
  DocumentFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<DocumentCardDto>>> getFiltered(
    DocumentFilter filter,
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

    final hasCurrentVersionExpr = db.documentItems.currentVersionId.isNotNull();

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final docItem = row.readTable(documentItems);
      final currentVersion = row.readTableOrNull(documentVersions);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = DocumentCardDto(
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
        document: DocumentCurrentVersionCardDataDto(
          currentVersionId: docItem.currentVersionId,
          currentVersionNumber: currentVersion?.versionNumber,
          documentType: row.readWithConverter<DocumentType?, String>(documentVersions.documentType),
          documentTypeOther: currentVersion?.documentTypeOther,
          pageCount: currentVersion?.pageCount,
          versionCreatedAt: currentVersion?.createdAt,
          versionModifiedAt: currentVersion?.modifiedAt,
          hasCurrentVersion: row.read(hasCurrentVersionExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(DocumentFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(DocumentFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.document);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.hasCurrentVersion != null) {
      if (filter.hasCurrentVersion!) {
        whereExpr &= documentItems.currentVersionId.isNotNull();
      } else {
        whereExpr &= documentItems.currentVersionId.isNull();
      }
    }

    if (filter.documentType != null) {
      whereExpr &= documentVersions.documentType.equalsValue(filter.documentType!);
    }

    if (filter.versionNumber != null) {
      whereExpr &= documentVersions.versionNumber.equals(filter.versionNumber!);
    }

    if (filter.minPageCount != null) {
      whereExpr &= documentVersions.pageCount.isBiggerOrEqualValue(filter.minPageCount!);
    }
    if (filter.maxPageCount != null) {
      whereExpr &= documentVersions.pageCount.isSmallerOrEqualValue(filter.maxPageCount!);
    }

    if (filter.hasAggregateHash != null) {
      if (filter.hasAggregateHash!) {
        whereExpr &= documentVersions.aggregateSha256Hash.isNotNull();
      } else {
        whereExpr &= documentVersions.aggregateSha256Hash.isNull();
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q);
      whereExpr &= textExpr;
    }

    final hasCurrentVersionExpr = db.documentItems.currentVersionId.isNotNull();

    final query = select(vaultItems).join([
      innerJoin(documentItems, documentItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(documentVersions, documentVersions.id.equalsExp(documentItems.currentVersionId)),
    ])
      ..where(whereExpr)
      ..addColumns([hasCurrentVersionExpr]);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case DocumentSortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case DocumentSortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case DocumentSortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case DocumentSortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case DocumentSortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case DocumentSortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
