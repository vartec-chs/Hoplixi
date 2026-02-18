import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/files_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/file_items.dart';
import 'package:hoplixi/main_store/tables/file_metadata.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'file_filter_dao.g.dart';

@DriftAccessor(
  tables: [
    VaultItems,
    FileItems,
    FileMetadata,
    Categories,
    Tags,
    ItemTags,
    NoteItems,
  ],
)
class FileFilterDao extends DatabaseAccessor<MainStore>
    with _$FileFilterDaoMixin
    implements FilterDao<FilesFilter, FileCardDto> {
  FileFilterDao(super.db);

  @override
  Future<List<FileCardDto>> getFiltered(FilesFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(fileItems, fileItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(
        fileMetadata,
        fileMetadata.id.equalsExp(fileItems.metadataId),
      ),
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
      final fi = row.readTable(fileItems);
      final category = row.readTableOrNull(categories);
      final metadata = row.readTableOrNull(fileMetadata);

      return FileCardDto(
        id: item.id,
        name: item.name,
        metadataId: fi.metadataId,
        fileName: metadata?.fileName,
        fileExtension: metadata?.fileExtension,
        fileSize: metadata?.fileSize,
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
  Future<int> countFiltered(FilesFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(fileItems, fileItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(
        fileMetadata,
        fileMetadata.id.equalsExp(fileItems.metadataId),
      ),
    ]);
    query.where(_buildWhereExpression(filter));
    final results = await query.get();
    return results.length;
  }

  Expression<bool> _buildWhereExpression(FilesFilter filter) {
    Expression<bool> expr = const Constant(true);
    expr = expr & _applyBaseFilters(filter.base);
    expr = expr & _applyFileSpecificFilters(filter);
    return expr;
  }

  Expression<bool> _applyBaseFilters(BaseFilter base) {
    Expression<bool> expr = const Constant(true);

    if (base.query.isNotEmpty) {
      final q = base.query.toLowerCase();
      Expression<bool> searchExpr =
          vaultItems.name.lower().like('%$q%') |
          vaultItems.description.lower().like('%$q%') |
          fileMetadata.fileName.lower().like('%$q%');
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

  Expression<bool> _applyFileSpecificFilters(FilesFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.fileExtensions.isNotEmpty) {
      Expression<bool>? extExpr;
      for (final ext in filter.fileExtensions) {
        final cond = fileMetadata.fileExtension.lower().equals(
          ext.toLowerCase(),
        );
        extExpr = extExpr == null ? cond : (extExpr | cond);
      }
      if (extExpr != null) {
        expr = expr & extExpr;
      }
    }

    if (filter.mimeTypes.isNotEmpty) {
      Expression<bool>? mimeExpr;
      for (final mime in filter.mimeTypes) {
        final cond = fileMetadata.mimeType.lower().equals(mime.toLowerCase());
        mimeExpr = mimeExpr == null ? cond : (mimeExpr | cond);
      }
      if (mimeExpr != null) {
        expr = expr & mimeExpr;
      }
    }

    if (filter.fileName != null && filter.fileName!.isNotEmpty) {
      expr =
          expr &
          fileMetadata.fileName.lower().like(
            '%${filter.fileName!.toLowerCase()}%',
          );
    }

    if (filter.minFileSize != null) {
      expr =
          expr &
          fileMetadata.fileSize.isBiggerOrEqualValue(filter.minFileSize!);
    }
    if (filter.maxFileSize != null) {
      expr =
          expr &
          fileMetadata.fileSize.isSmallerOrEqualValue(filter.maxFileSize!);
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

  List<OrderingTerm> _buildOrderBy(FilesFilter filter) {
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
        case FilesSortField.name:
          terms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
        case FilesSortField.fileName:
          terms.add(
            OrderingTerm(expression: fileMetadata.fileName, mode: mode),
          );
        case FilesSortField.fileSize:
          terms.add(
            OrderingTerm(expression: fileMetadata.fileSize, mode: mode),
          );
        case FilesSortField.fileExtension:
          terms.add(
            OrderingTerm(expression: fileMetadata.fileExtension, mode: mode),
          );
        case FilesSortField.mimeType:
          terms.add(
            OrderingTerm(expression: fileMetadata.mimeType, mode: mode),
          );
        case FilesSortField.createdAt:
          terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
        case FilesSortField.modifiedAt:
          terms.add(
            OrderingTerm(expression: vaultItems.modifiedAt, mode: mode),
          );
        case FilesSortField.lastAccessed:
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
