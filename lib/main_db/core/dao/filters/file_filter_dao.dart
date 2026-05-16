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
    final whereExpr = _buildWhere(filter);
    final hasMetadataExpr = db.fileItems.metadataId.isNotNull();
    final hasSha256Expr = db.fileMetadata.sha256.isNotNull();

    final query = selectOnly(vaultItems).join([
      innerJoin(fileItems, fileItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(
          fileMetadata, fileMetadata.id.equalsExp(fileItems.metadataId)),
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
        fileItems.metadataId,
        fileMetadata.fileName,
        fileMetadata.fileExtension,
        fileMetadata.mimeType,
        fileMetadata.fileSize,
        fileMetadata.availabilityStatus,
        fileMetadata.integrityStatus,
        fileMetadata.missingDetectedAt,
        fileMetadata.deletedAt,
        fileMetadata.lastIntegrityCheckAt,
        hasMetadataExpr,
        hasSha256Expr,
      ])
      ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case FileSortField.name:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case FileSortField.fileName:
          orderingTerms.add(
              OrderingTerm(expression: fileMetadata.fileName, mode: mode));
          break;
        case FileSortField.fileSize:
          orderingTerms.add(
              OrderingTerm(expression: fileMetadata.fileSize, mode: mode));
          break;
        case FileSortField.createdAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case FileSortField.modifiedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case FileSortField.lastUsedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case FileSortField.usedCount:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case FileSortField.recentScore:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.recentScore, mode: mode));
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

      final cardDto = FileCardDto(
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
        file: FileCardDataDto(
          metadataId: row.read(fileItems.metadataId),
          fileName: row.read(fileMetadata.fileName),
          fileExtension: row.read(fileMetadata.fileExtension),
          mimeType: row.read(fileMetadata.mimeType),
          fileSize: row.read(fileMetadata.fileSize),
          availabilityStatus: row.readWithConverter<FileAvailabilityStatus?,
              String>(fileMetadata.availabilityStatus),
          integrityStatus: row.readWithConverter<FileIntegrityStatus?, String>(
              fileMetadata.integrityStatus),
          missingDetectedAt: row.read(fileMetadata.missingDetectedAt),
          deletedAt: row.read(fileMetadata.deletedAt),
          lastIntegrityCheckAt: row.read(fileMetadata.lastIntegrityCheckAt),
          hasMetadata: row.read(hasMetadataExpr) ?? false,
          hasSha256: row.read(hasSha256Expr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(FileFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query = selectOnly(vaultItems).join([
      innerJoin(fileItems, fileItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(
          fileMetadata, fileMetadata.id.equalsExp(fileItems.metadataId)),
    ])
      ..addColumns([countExp])
      ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(FileFilter filter) {
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
      whereExpr &=
          fileMetadata.fileSize.isBiggerOrEqualValue(filter.minFileSize!);
    }
    if (filter.maxFileSize != null) {
      whereExpr &=
          fileMetadata.fileSize.isSmallerOrEqualValue(filter.maxFileSize!);
    }

    if (filter.availabilityStatus != null) {
      whereExpr &= fileMetadata.availabilityStatus
          .equalsValue(filter.availabilityStatus!);
    }
    if (filter.integrityStatus != null) {
      whereExpr &=
          fileMetadata.integrityStatus.equalsValue(filter.integrityStatus!);
    }

    if (filter.missingDetectedAfter != null) {
      whereExpr &= fileMetadata.missingDetectedAt
          .isBiggerOrEqualValue(filter.missingDetectedAfter!);
    }
    if (filter.deletedAfter != null) {
      whereExpr &=
          fileMetadata.deletedAt.isBiggerOrEqualValue(filter.deletedAfter!);
    }
    if (filter.lastIntegrityCheckAfter != null) {
      whereExpr &= fileMetadata.lastIntegrityCheckAt
          .isBiggerOrEqualValue(filter.lastIntegrityCheckAfter!);
    }
    if (filter.lastIntegrityCheckBefore != null) {
      whereExpr &= fileMetadata.lastIntegrityCheckAt
          .isSmallerOrEqualValue(filter.lastIntegrityCheckBefore!);
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

    return whereExpr;
  }
}
