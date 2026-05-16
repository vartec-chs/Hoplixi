import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/password/password_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'password_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  PasswordItems,
  Categories,
  Tags,
  ItemTags,
])
class PasswordFilterDao extends DatabaseAccessor<MainStore>
    with _$PasswordFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<PasswordFilter, FilteredCardDto<PasswordCardDto>> {
  PasswordFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<PasswordCardDto>>> getFiltered(
    PasswordFilter filter,
  ) async {
    final whereExpr = _buildWhere(filter);
    final hasPasswordExpr = passwordItems.password.isNotNull();

    final query = selectOnly(vaultItems).join([
      innerJoin(passwordItems, passwordItems.itemId.equalsExp(vaultItems.id)),
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
        passwordItems.login,
        passwordItems.email,
        passwordItems.url,
        passwordItems.expiresAt,
        hasPasswordExpr,
      ])
      ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case PasswordSortField.name:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case PasswordSortField.login:
          orderingTerms.add(
              OrderingTerm(expression: passwordItems.login, mode: mode));
          break;
        case PasswordSortField.email:
          orderingTerms.add(
              OrderingTerm(expression: passwordItems.email, mode: mode));
          break;
        case PasswordSortField.url:
          orderingTerms.add(
              OrderingTerm(expression: passwordItems.url, mode: mode));
          break;
        case PasswordSortField.expiresAt:
          orderingTerms.add(
              OrderingTerm(expression: passwordItems.expiresAt, mode: mode));
          break;
        case PasswordSortField.createdAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case PasswordSortField.modifiedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case PasswordSortField.lastUsedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case PasswordSortField.usedCount:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case PasswordSortField.recentScore:
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

      final cardDto = PasswordCardDto(
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
        password: PasswordCardDataDto(
          login: row.read(passwordItems.login),
          email: row.read(passwordItems.email),
          url: row.read(passwordItems.url),
          expiresAt: row.read(passwordItems.expiresAt),
          hasPassword: row.read(hasPasswordExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(PasswordFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query = selectOnly(vaultItems).join([
      innerJoin(passwordItems, passwordItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..addColumns([countExp])
      ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(PasswordFilter filter) {
    Expression<bool> whereExpr =
        vaultItems.type.equalsValue(VaultItemType.password);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.name != null) {
      whereExpr &= vaultItems.name.contains(filter.name!);
    }
    if (filter.login != null) {
      whereExpr &= passwordItems.login.contains(filter.login!);
    }
    if (filter.email != null) {
      whereExpr &= passwordItems.email.contains(filter.email!);
    }
    if (filter.url != null) {
      whereExpr &= passwordItems.url.contains(filter.url!);
    }

    if (filter.hasLogin != null) {
      if (filter.hasLogin!) {
        whereExpr &= passwordItems.login.isNotNull();
      } else {
        whereExpr &= passwordItems.login.isNull();
      }
    }
    if (filter.hasEmail != null) {
      if (filter.hasEmail!) {
        whereExpr &= passwordItems.email.isNotNull();
      } else {
        whereExpr &= passwordItems.email.isNull();
      }
    }
    if (filter.hasUrl != null) {
      if (filter.hasUrl!) {
        whereExpr &= passwordItems.url.isNotNull();
      } else {
        whereExpr &= passwordItems.url.isNull();
      }
    }
    if (filter.hasPassword != null) {
      if (filter.hasPassword!) {
        whereExpr &= passwordItems.password.isNotNull();
      } else {
        whereExpr &= passwordItems.password.isNull();
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          passwordItems.login.like(q) |
          passwordItems.email.like(q) |
          passwordItems.url.like(q);
      whereExpr &= textExpr;
    }

    return whereExpr;
  }
}
