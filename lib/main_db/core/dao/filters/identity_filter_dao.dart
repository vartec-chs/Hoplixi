import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/identity/identity_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'identity_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  IdentityItems,
  Categories,
  Tags,
  ItemTags,
])
class IdentityFilterDao extends DatabaseAccessor<MainStore>
    with _$IdentityFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<IdentityFilter, FilteredCardDto<IdentityCardDto>> {
  IdentityFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<IdentityCardDto>>> getFiltered(
    IdentityFilter filter,
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

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final identity = row.readTable(identityItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = IdentityCardDto(
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
        identity: IdentityCardDataDto(
          displayName: identity.displayName,
          username: identity.username,
          email: identity.email,
          phone: identity.phone,
          company: identity.company,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(IdentityFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(IdentityFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.identity);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.firstName != null) {
      whereExpr &= identityItems.firstName.contains(filter.firstName!);
    }
    if (filter.lastName != null) {
      whereExpr &= identityItems.lastName.contains(filter.lastName!);
    }
    if (filter.displayName != null) {
      whereExpr &= identityItems.displayName.contains(filter.displayName!);
    }
    if (filter.username != null) {
      whereExpr &= identityItems.username.contains(filter.username!);
    }
    if (filter.email != null) {
      whereExpr &= identityItems.email.contains(filter.email!);
    }
    if (filter.phone != null) {
      whereExpr &= identityItems.phone.contains(filter.phone!);
    }
    if (filter.company != null) {
      whereExpr &= identityItems.company.contains(filter.company!);
    }
    if (filter.jobTitle != null) {
      whereExpr &= identityItems.jobTitle.contains(filter.jobTitle!);
    }
    if (filter.website != null) {
      whereExpr &= identityItems.website.contains(filter.website!);
    }

    if (filter.hasTaxId != null) {
      if (filter.hasTaxId!) {
        whereExpr &= identityItems.taxId.isNotNull();
      } else {
        whereExpr &= identityItems.taxId.isNull();
      }
    }
    if (filter.hasNationalId != null) {
      if (filter.hasNationalId!) {
        whereExpr &= identityItems.nationalId.isNotNull();
      } else {
        whereExpr &= identityItems.nationalId.isNull();
      }
    }
    if (filter.hasPassportNumber != null) {
      if (filter.hasPassportNumber!) {
        whereExpr &= identityItems.passportNumber.isNotNull();
      } else {
        whereExpr &= identityItems.passportNumber.isNull();
      }
    }
    if (filter.hasDriverLicenseNumber != null) {
      if (filter.hasDriverLicenseNumber!) {
        whereExpr &= identityItems.driverLicenseNumber.isNotNull();
      } else {
        whereExpr &= identityItems.driverLicenseNumber.isNull();
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          identityItems.firstName.like(q) |
          identityItems.lastName.like(q) |
          identityItems.displayName.like(q) |
          identityItems.username.like(q) |
          identityItems.email.like(q) |
          identityItems.company.like(q);
      whereExpr &= textExpr;
    }

    final query = select(vaultItems).join([
      innerJoin(identityItems, identityItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..where(whereExpr);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case IdentitySortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case IdentitySortField.displayName:
          orderingTerms.add(OrderingTerm(expression: identityItems.displayName, mode: mode));
          break;
        case IdentitySortField.username:
          orderingTerms.add(OrderingTerm(expression: identityItems.username, mode: mode));
          break;
        case IdentitySortField.email:
          orderingTerms.add(OrderingTerm(expression: identityItems.email, mode: mode));
          break;
        case IdentitySortField.company:
          orderingTerms.add(OrderingTerm(expression: identityItems.company, mode: mode));
          break;
        case IdentitySortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case IdentitySortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case IdentitySortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case IdentitySortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case IdentitySortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
