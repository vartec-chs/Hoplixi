import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/documents_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/document_items.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'document_filter_dao.g.dart';

@DriftAccessor(
  tables: [VaultItems, DocumentItems, Categories, Tags, ItemTags, NoteItems],
)
class DocumentFilterDao extends DatabaseAccessor<MainStore>
    with _$DocumentFilterDaoMixin
    implements FilterDao<DocumentsFilter, DocumentCardDto> {
  DocumentFilterDao(super.db);

  @override
  Future<List<DocumentCardDto>> getFiltered(DocumentsFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(documentItems, documentItems.itemId.equalsExp(vaultItems.id)),
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
      final doc = row.readTable(documentItems);
      final category = row.readTableOrNull(categories);
      final note = row.readTableOrNull(noteItems);

      return DocumentCardDto(
        id: item.id,
        title: item.name,
        documentType: doc.documentType,
        description: item.description,
        pageCount: doc.pageCount,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        noteId: item.noteId,
        noteName: note != null ? item.name : null,
        tags: tagsMap[item.id] ?? [],
        isFavorite: item.isFavorite,
        isArchived: item.isArchived,
        isPinned: item.isPinned,
        isDeleted: item.isDeleted,
        usedCount: item.usedCount,
        modifiedAt: item.modifiedAt,
      );
    }).toList();
  }

  @override
  Future<int> countFiltered(DocumentsFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(documentItems, documentItems.itemId.equalsExp(vaultItems.id)),
    ]);
    query.where(_buildWhereExpression(filter));
    final results = await query.get();
    return results.length;
  }

  Expression<bool> _buildWhereExpression(DocumentsFilter filter) {
    Expression<bool> expr = const Constant(true);
    expr = expr & _applyBaseFilters(filter.base);
    expr = expr & _applyDocumentSpecificFilters(filter);
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
              documentItems.aggregatedText.lower().like('%$q%'));
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

  Expression<bool> _applyDocumentSpecificFilters(DocumentsFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.documentTypes.isNotEmpty) {
      Expression<bool>? typeExpr;
      for (final type in filter.documentTypes) {
        final cond = documentItems.documentType.lower().equals(type);
        typeExpr = typeExpr == null ? cond : (typeExpr | cond);
      }
      if (typeExpr != null) {
        expr = expr & typeExpr;
      }
    }

    if (filter.titleQuery != null && filter.titleQuery!.isNotEmpty) {
      expr =
          expr &
          vaultItems.name.lower().like('%${filter.titleQuery!.toLowerCase()}%');
    }

    if (filter.descriptionQuery != null &&
        filter.descriptionQuery!.isNotEmpty) {
      expr =
          expr &
          vaultItems.description.lower().like(
            '%${filter.descriptionQuery!.toLowerCase()}%',
          );
    }

    if (filter.aggregatedTextQuery != null &&
        filter.aggregatedTextQuery!.isNotEmpty) {
      expr =
          expr &
          documentItems.aggregatedText.lower().like(
            '%${filter.aggregatedTextQuery!.toLowerCase()}%',
          );
    }

    if (filter.minPageCount != null) {
      expr =
          expr &
          documentItems.pageCount.isBiggerOrEqualValue(filter.minPageCount!);
    }
    if (filter.maxPageCount != null) {
      expr =
          expr &
          documentItems.pageCount.isSmallerOrEqualValue(filter.maxPageCount!);
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

  List<OrderingTerm> _buildOrderBy(DocumentsFilter filter) {
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
        case DocumentsSortField.title:
          terms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
        case DocumentsSortField.documentType:
          terms.add(
            OrderingTerm(expression: documentItems.documentType, mode: mode),
          );
        case DocumentsSortField.pageCount:
          terms.add(
            OrderingTerm(expression: documentItems.pageCount, mode: mode),
          );
        case DocumentsSortField.createdAt:
          terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
        case DocumentsSortField.modifiedAt:
          terms.add(
            OrderingTerm(expression: vaultItems.modifiedAt, mode: mode),
          );
        case DocumentsSortField.lastUsedAt:
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
