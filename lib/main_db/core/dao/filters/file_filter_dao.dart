import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/file/file_items.dart';
import '../../tables/file/file_metadata.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'file_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  FileItems,
  FileMetadata,
  Categories,
  Tags,
  ItemTags,
])
class FileFilterDao extends DatabaseAccessor<MainStore>
    with _$FileFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<FileFilter, FilteredCardDto<FileCardDto>> {
  FileFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<FileCardDto>>> getFiltered(
    FileFilter filter,
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

    final hasMetadataExpr = db.fileItems.metadataId.isNotNull();
    final hasSha256Expr = db.fileMetadata.sha256.isNotNull();

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final file = row.readTable(fileItems);
      final metadata = row.readTableOrNull(fileMetadata);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = FileCardDto(
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
        file: FileCardDataDto(
          metadataId: file.metadataId,
          fileName: metadata?.fileName,
          fileExtension: metadata?.fileExtension,
          mimeType: metadata?.mimeType,
          fileSize: metadata?.fileSize,
          availabilityStatus: row.readWithConverter<FileAvailabilityStatus?, String>(fileMetadata.availabilityStatus),
          integrityStatus: row.readWithConverter<FileIntegrityStatus?, String>(fileMetadata.integrityStatus),
          missingDetectedAt: metadata?.missingDetectedAt,
          deletedAt: metadata?.deletedAt,
          lastIntegrityCheckAt: metadata?.lastIntegrityCheckAt,
          hasMetadata: row.read(hasMetadataExpr) ?? false,
          hasSha256: row.read(hasSha256Expr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(FileFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(FileFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.file);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.fileName != null) {
      whereExpr &= fileMetadata.fileName.contains(filter.fileName!);
    }
    if (filter.fileExtension != null) {
      whereExpr &= fileMetadata.fileExtension.equals(filter.fileExtension!);
    }
    if (filter.mimeType != null) {
      whereExpr &= fileMetadata.mimeType.contains(filter.mimeType!);
    }

    if (filter.minFileSize != null) {
      whereExpr &= fileMetadata.fileSize.isBiggerOrEqualValue(filter.minFileSize!);
    }
    if (filter.maxFileSize != null) {
      whereExpr &= fileMetadata.fileSize.isSmallerOrEqualValue(filter.maxFileSize!);
    }

    if (filter.availabilityStatus != null) {
      whereExpr &= fileMetadata.availabilityStatus.equalsValue(filter.availabilityStatus!);
    }
    if (filter.integrityStatus != null) {
      whereExpr &= fileMetadata.integrityStatus.equalsValue(filter.integrityStatus!);
    }

    if (filter.missingDetectedAfter != null) {
      whereExpr &= fileMetadata.missingDetectedAt.isBiggerOrEqualValue(filter.missingDetectedAfter!);
    }
    if (filter.deletedAfter != null) {
      whereExpr &= fileMetadata.deletedAt.isBiggerOrEqualValue(filter.deletedAfter!);
    }
    if (filter.lastIntegrityCheckAfter != null) {
      whereExpr &= fileMetadata.lastIntegrityCheckAt.isBiggerOrEqualValue(filter.lastIntegrityCheckAfter!);
    }
    if (filter.lastIntegrityCheckBefore != null) {
      whereExpr &= fileMetadata.lastIntegrityCheckAt.isSmallerOrEqualValue(filter.lastIntegrityCheckBefore!);
    }

    if (filter.hasSha256 != null) {
      if (filter.hasSha256!) {
        whereExpr &= fileMetadata.sha256.isNotNull();
      } else {
        whereExpr &= fileMetadata.sha256.isNull();
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          fileMetadata.fileName.like(q);
      whereExpr &= textExpr;
    }

    final hasMetadataExpr = db.fileItems.metadataId.isNotNull();
    final hasSha256Expr = db.fileMetadata.sha256.isNotNull();

    final query = select(vaultItems).join([
      innerJoin(fileItems, fileItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(fileMetadata, fileMetadata.id.equalsExp(fileItems.metadataId)),
    ])
      ..where(whereExpr)
      ..addColumns([hasMetadataExpr, hasSha256Expr]);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case FileSortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case FileSortField.fileName:
          orderingTerms.add(OrderingTerm(expression: fileMetadata.fileName, mode: mode));
          break;
        case FileSortField.fileSize:
          orderingTerms.add(OrderingTerm(expression: fileMetadata.fileSize, mode: mode));
          break;
        case FileSortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case FileSortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case FileSortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case FileSortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case FileSortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
