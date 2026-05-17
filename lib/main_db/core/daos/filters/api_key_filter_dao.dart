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
    final whereExpr = _buildWhere(filter);
    final hasKeyExpr = apiKeyItems.key.isNotNull();

    final query =
        selectOnly(vaultItems).join([
            innerJoin(apiKeyItems, apiKeyItems.itemId.equalsExp(vaultItems.id)),
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
            apiKeyItems.service,
            apiKeyItems.tokenType,
            apiKeyItems.environment,
            apiKeyItems.expiresAt,
            apiKeyItems.revokedAt,
            apiKeyItems.rotationPeriodDays,
            apiKeyItems.lastRotatedAt,
            apiKeyItems.owner,
            apiKeyItems.baseUrl,
            hasKeyExpr,
          ])
          ..where(whereExpr);

    applyLimitOffset(query, filter.base);

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

      final cardDto = ApiKeyCardDto(
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
        apiKey: ApiKeyCardDataDto(
          service: row.read(apiKeyItems.service)!,
          tokenType: row.readWithConverter<ApiKeyTokenType?, String>(
            apiKeyItems.tokenType,
          ),
          environment: row.readWithConverter<ApiKeyEnvironment?, String>(
            apiKeyItems.environment,
          ),
          expiresAt: row.read(apiKeyItems.expiresAt),
          revokedAt: row.read(apiKeyItems.revokedAt),
          rotationPeriodDays: row.read(apiKeyItems.rotationPeriodDays),
          lastRotatedAt: row.read(apiKeyItems.lastRotatedAt),
          owner: row.read(apiKeyItems.owner),
          baseUrl: row.read(apiKeyItems.baseUrl),
          hasKey: row.read(hasKeyExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(ApiKeyFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query =
        selectOnly(vaultItems).join([
            innerJoin(apiKeyItems, apiKeyItems.itemId.equalsExp(vaultItems.id)),
          ])
          ..addColumns([countExp])
          ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(ApiKeyFilter filter) {
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

    return whereExpr;
  }
}
