import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/api_key_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/api_keys_filter.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/tables/api_key_items.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'api_key_filter_dao.g.dart';

@DriftAccessor(
  tables: [VaultItems, ApiKeyItems, Categories, Tags, ItemTags, NoteItems],
)
class ApiKeyFilterDao extends DatabaseAccessor<MainStore>
    with _$ApiKeyFilterDaoMixin
    implements FilterDao<ApiKeysFilter, ApiKeyCardDto> {
  ApiKeyFilterDao(super.db);

  @override
  Future<List<ApiKeyCardDto>> getFiltered(ApiKeysFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(apiKeyItems, apiKeyItems.itemId.equalsExp(vaultItems.id)),
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
      final api = row.readTable(apiKeyItems);
      final category = row.readTableOrNull(categories);

      return ApiKeyCardDto(
        id: item.id,
        name: item.name,
        service: api.service,
        maskedKey: api.maskedKey,
        tokenType: api.tokenType,
        environment: api.environment,
        expiresAt: api.expiresAt,
        revoked: api.revoked,
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
        usedCount: item.usedCount,
        modifiedAt: item.modifiedAt,
        createdAt: item.createdAt,
      );
    }).toList();
  }

  @override
  Future<int> countFiltered(ApiKeysFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(apiKeyItems, apiKeyItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    final rows = await query.get();
    return rows.length;
  }

  Expression<bool> _buildWhereExpression(ApiKeysFilter filter) {
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
              apiKeyItems.service.lower().like('%$q%') |
              apiKeyItems.environment.lower().like('%$q%') |
              apiKeyItems.tokenType.lower().like('%$q%') |
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

  Expression<bool> _applySpecificFilters(ApiKeysFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.name != null) {
      expr =
          expr &
          vaultItems.name.lower().like('%${filter.name!.toLowerCase()}%');
    }

    if (filter.service != null) {
      expr =
          expr &
          apiKeyItems.service.lower().like(
            '%${filter.service!.toLowerCase()}%',
          );
    }

    if (filter.tokenType != null) {
      expr =
          expr &
          apiKeyItems.tokenType.lower().like(
            '%${filter.tokenType!.toLowerCase()}%',
          );
    }

    if (filter.environment != null) {
      expr =
          expr &
          apiKeyItems.environment.lower().like(
            '%${filter.environment!.toLowerCase()}%',
          );
    }

    if (filter.revoked != null) {
      expr = expr & apiKeyItems.revoked.equals(filter.revoked!);
    }

    if (filter.hasExpiration != null) {
      expr =
          expr &
          (filter.hasExpiration!
              ? apiKeyItems.expiresAt.isNotNull()
              : apiKeyItems.expiresAt.isNull());
    }

    return expr;
  }

  List<OrderingTerm> _buildOrderBy(ApiKeysFilter filter) {
    final terms = <OrderingTerm>[
      OrderingTerm(expression: vaultItems.isPinned, mode: OrderingMode.desc),
    ];

    final mode = filter.base.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    switch (filter.sortField) {
      case ApiKeysSortField.name:
        terms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
      case ApiKeysSortField.service:
        terms.add(OrderingTerm(expression: apiKeyItems.service, mode: mode));
      case ApiKeysSortField.environment:
        terms.add(
          OrderingTerm(expression: apiKeyItems.environment, mode: mode),
        );
      case ApiKeysSortField.expiresAt:
        terms.add(OrderingTerm(expression: apiKeyItems.expiresAt, mode: mode));
      case ApiKeysSortField.createdAt:
        terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
      case ApiKeysSortField.modifiedAt:
        terms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
      case ApiKeysSortField.lastAccessed:
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
