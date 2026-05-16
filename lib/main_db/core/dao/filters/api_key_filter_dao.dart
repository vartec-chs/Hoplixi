import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/api_key/api_key_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'api_key_filter_dao.g.dart';

@DriftAccessor(tables: [VaultItems, ApiKeyItems, Categories, Tags, ItemTags])
class ApiKeyFilterDao extends DatabaseAccessor<MainStore>
    with _$ApiKeyFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<ApiKeyFilter, FilteredCardDto<ApiKeyCardDto>> {
  ApiKeyFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<ApiKeyCardDto>>> getFiltered(
    ApiKeyFilter filter,
  ) async {
    final query = _buildQuery(filter);
    applyLimitOffset(query, filter.base);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final categoryIds = rows
        .map((r) => r.readTable(vaultItems).categoryId)
        .whereType<String>()
        .toList();

    final categoriesMap = await loadCategoriesForItems(categoryIds);
    final tagsMap = await loadTagsForItems(itemIds);

    final hasKeyExpr = db.apiKeyItems.key.isNotNull();

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final apiKey = row.readTable(apiKeyItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = ApiKeyCardDto(
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
        apiKey: ApiKeyCardDataDto(
          service: apiKey.service,
          tokenType: row.readWithConverter<ApiKeyTokenType?, String>(
            apiKeyItems.tokenType,
          ),
          environment: row.readWithConverter<ApiKeyEnvironment?, String>(
            apiKeyItems.environment,
          ),
          expiresAt: apiKey.expiresAt,
          revokedAt: apiKey.revokedAt,
          rotationPeriodDays: apiKey.rotationPeriodDays,
          lastRotatedAt: apiKey.lastRotatedAt,
          owner: apiKey.owner,
          baseUrl: apiKey.baseUrl,
          hasKey: row.read(hasKeyExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(ApiKeyFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(
    ApiKeyFilter filter,
  ) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(
      VaultItemType.apiKey,
    );

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.name != null) {
      whereExpr &= vaultItems.name.contains(filter.name!);
    }
    if (filter.service != null) {
      whereExpr &= apiKeyItems.service.contains(filter.service!);
    }
    if (filter.tokenType != null) {
      whereExpr &= apiKeyItems.tokenType.equalsValue(filter.tokenType!);
    }
    if (filter.environment != null) {
      whereExpr &= apiKeyItems.environment.equalsValue(filter.environment!);
    }
    if (filter.isRevoked != null) {
      if (filter.isRevoked!) {
        whereExpr &= apiKeyItems.revokedAt.isNotNull();
      } else {
        whereExpr &= apiKeyItems.revokedAt.isNull();
      }
    }
    if (filter.hasExpiration != null) {
      if (filter.hasExpiration!) {
        whereExpr &= apiKeyItems.expiresAt.isNotNull();
      } else {
        whereExpr &= apiKeyItems.expiresAt.isNull();
      }
    }
    if (filter.hasOwner != null) {
      if (filter.hasOwner!) {
        whereExpr &= apiKeyItems.owner.isNotNull();
      } else {
        whereExpr &= apiKeyItems.owner.isNull();
      }
    }
    if (filter.hasBaseUrl != null) {
      if (filter.hasBaseUrl!) {
        whereExpr &= apiKeyItems.baseUrl.isNotNull();
      } else {
        whereExpr &= apiKeyItems.baseUrl.isNull();
      }
    }
    if (filter.hasScopes != null) {
      if (filter.hasScopes!) {
        whereExpr &= apiKeyItems.scopesText.isNotNull();
      } else {
        whereExpr &= apiKeyItems.scopesText.isNull();
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr =
          vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          apiKeyItems.service.like(q) |
          apiKeyItems.owner.like(q) |
          apiKeyItems.baseUrl.like(q) |
          apiKeyItems.scopesText.like(q);
      whereExpr &= textExpr;
    }

    final hasKeyExpr = db.apiKeyItems.key.isNotNull();

    final query =
        select(vaultItems).join([
            innerJoin(apiKeyItems, apiKeyItems.itemId.equalsExp(vaultItems.id)),
          ])
          ..where(whereExpr)
          ..addColumns([hasKeyExpr]);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case ApiKeySortField.name:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.name, mode: mode),
          );
          break;
        case ApiKeySortField.service:
          orderingTerms.add(
            OrderingTerm(expression: apiKeyItems.service, mode: mode),
          );
          break;
        case ApiKeySortField.tokenType:
          orderingTerms.add(
            OrderingTerm(expression: apiKeyItems.tokenType, mode: mode),
          );
          break;
        case ApiKeySortField.environment:
          orderingTerms.add(
            OrderingTerm(expression: apiKeyItems.environment, mode: mode),
          );
          break;
        case ApiKeySortField.expiresAt:
          orderingTerms.add(
            OrderingTerm(expression: apiKeyItems.expiresAt, mode: mode),
          );
          break;
        case ApiKeySortField.revokedAt:
          orderingTerms.add(
            OrderingTerm(expression: apiKeyItems.revokedAt, mode: mode),
          );
          break;
        case ApiKeySortField.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.createdAt, mode: mode),
          );
          break;
        case ApiKeySortField.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.modifiedAt, mode: mode),
          );
          break;
        case ApiKeySortField.lastUsedAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode),
          );
          break;
        case ApiKeySortField.usedCount:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.usedCount, mode: mode),
          );
          break;
        case ApiKeySortField.recentScore:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.recentScore, mode: mode),
          );
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
