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

@DriftAccessor(
  tables: [
    VaultItems,
    DocumentItems,
    DocumentVersions,
    Categories,
    Tags,
    ItemTags,
  ],
)
class DocumentFilterDao extends DatabaseAccessor<MainStore>
    with _$DocumentFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<DocumentFilter, FilteredCardDto<DocumentCardDto>> {
  DocumentFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<DocumentCardDto>>> getFiltered(
    DocumentFilter filter,
  ) async {
    final whereExpr = _buildWhere(filter);
    final hasCurrentVersionExpr = db.documentItems.currentVersionId.isNotNull();

    final query =
        selectOnly(vaultItems).join([
            innerJoin(
              documentItems,
              documentItems.itemId.equalsExp(vaultItems.id),
            ),
            leftOuterJoin(
              documentVersions,
              documentVersions.id.equalsExp(documentItems.currentVersionId),
            ),
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
            documentItems.currentVersionId,
            documentVersions.versionNumber,
            documentVersions.documentType,
            documentVersions.documentTypeOther,
            documentVersions.pageCount,
            documentVersions.createdAt,
            documentVersions.modifiedAt,
            hasCurrentVersionExpr,
          ])
          ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case DocumentSortField.name:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.name, mode: mode),
          );
          break;
        case DocumentSortField.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.createdAt, mode: mode),
          );
          break;
        case DocumentSortField.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.modifiedAt, mode: mode),
          );
          break;
        case DocumentSortField.lastUsedAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode),
          );
          break;
        case DocumentSortField.usedCount:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.usedCount, mode: mode),
          );
          break;
        case DocumentSortField.recentScore:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.recentScore, mode: mode),
          );
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

      final cardDto = DocumentCardDto(
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
        document: DocumentCurrentVersionCardDataDto(
          currentVersionId: row.read(documentItems.currentVersionId),
          currentVersionNumber: row.read(documentVersions.versionNumber),
          documentType: row.readWithConverter<DocumentType?, String>(
            documentVersions.documentType,
          ),
          documentTypeOther: row.read(documentVersions.documentTypeOther),
          pageCount: row.read(documentVersions.pageCount),
          versionCreatedAt: row.read(documentVersions.createdAt),
          versionModifiedAt: row.read(documentVersions.modifiedAt),
          hasCurrentVersion: row.read(hasCurrentVersionExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(DocumentFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query =
        selectOnly(vaultItems).join([
            innerJoin(
              documentItems,
              documentItems.itemId.equalsExp(vaultItems.id),
            ),
            leftOuterJoin(
              documentVersions,
              documentVersions.id.equalsExp(documentItems.currentVersionId),
            ),
          ])
          ..addColumns([countExp])
          ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(DocumentFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(
      VaultItemType.document,
    );

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.hasCurrentVersion != null) {
      if (filter.hasCurrentVersion!) {
        whereExpr &= documentItems.currentVersionId.isNotNull();
      } else {
        whereExpr &= documentItems.currentVersionId.isNull();
      }
    }

    if (filter.documentType != null) {
      whereExpr &= documentVersions.documentType.equalsValue(
        filter.documentType!,
      );
    }

    if (filter.versionNumber != null) {
      whereExpr &= documentVersions.versionNumber.equals(filter.versionNumber!);
    }

    if (filter.minPageCount != null) {
      whereExpr &= documentVersions.pageCount.isBiggerOrEqualValue(
        filter.minPageCount!,
      );
    }
    if (filter.maxPageCount != null) {
      whereExpr &= documentVersions.pageCount.isSmallerOrEqualValue(
        filter.maxPageCount!,
      );
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
      final textExpr = vaultItems.name.like(q) | vaultItems.description.like(q);
      whereExpr &= textExpr;
    }

    return whereExpr;
  }
}
