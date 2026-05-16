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
    final query = _buildQuery(filter);
    applyLimitOffset(query, filter.base);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final categoryIds =
        rows.map((r) => r.readTable(vaultItems).categoryId).whereType<String>().toList();

    final categoriesMap = await loadCategoriesForItems(categoryIds);
    final tagsMap = await loadTagsForItems(itemIds);

    final hasPasswordExpr = db.passwordItems.password.isNotNull();

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final password = row.readTable(passwordItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = PasswordCardDto(
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
        password: PasswordCardDataDto(
          login: password.login,
          email: password.email,
          url: password.url,
          expiresAt: password.expiresAt,
          hasPassword: row.read(hasPasswordExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(PasswordFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(PasswordFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.password);

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

    final hasPasswordExpr = db.passwordItems.password.isNotNull();

    final query = select(vaultItems).join([
      innerJoin(passwordItems, passwordItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..where(whereExpr)
      ..addColumns([hasPasswordExpr]);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case PasswordSortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case PasswordSortField.login:
          orderingTerms.add(OrderingTerm(expression: passwordItems.login, mode: mode));
          break;
        case PasswordSortField.email:
          orderingTerms.add(OrderingTerm(expression: passwordItems.email, mode: mode));
          break;
        case PasswordSortField.url:
          orderingTerms.add(OrderingTerm(expression: passwordItems.url, mode: mode));
          break;
        case PasswordSortField.expiresAt:
          orderingTerms.add(OrderingTerm(expression: passwordItems.expiresAt, mode: mode));
          break;
        case PasswordSortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case PasswordSortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case PasswordSortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case PasswordSortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case PasswordSortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
