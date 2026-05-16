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

@DriftAccessor(tables: [VaultItems, IdentityItems, Categories, Tags, ItemTags])
class IdentityFilterDao extends DatabaseAccessor<MainStore>
    with _$IdentityFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<IdentityFilter, FilteredCardDto<IdentityCardDto>> {
  IdentityFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<IdentityCardDto>>> getFiltered(
    IdentityFilter filter,
  ) async {
    final whereExpr = _buildWhere(filter);
    final hasTaxIdExpr = identityItems.taxId.isNotNull();
    final hasNationalIdExpr = identityItems.nationalId.isNotNull();
    final hasPassportNumberExpr = identityItems.passportNumber.isNotNull();
    final hasDriverLicenseNumberExpr = identityItems.driverLicenseNumber
        .isNotNull();

    final query =
        selectOnly(vaultItems).join([
            innerJoin(
              identityItems,
              identityItems.itemId.equalsExp(vaultItems.id),
            ),
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
            identityItems.displayName,
            identityItems.username,
            identityItems.email,
            identityItems.phone,
            identityItems.company,
            hasTaxIdExpr,
            hasNationalIdExpr,
            hasPassportNumberExpr,
            hasDriverLicenseNumberExpr,
          ])
          ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case IdentitySortField.name:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.name, mode: mode),
          );
          break;
        case IdentitySortField.displayName:
          orderingTerms.add(
            OrderingTerm(expression: identityItems.displayName, mode: mode),
          );
          break;
        case IdentitySortField.username:
          orderingTerms.add(
            OrderingTerm(expression: identityItems.username, mode: mode),
          );
          break;
        case IdentitySortField.email:
          orderingTerms.add(
            OrderingTerm(expression: identityItems.email, mode: mode),
          );
          break;
        case IdentitySortField.company:
          orderingTerms.add(
            OrderingTerm(expression: identityItems.company, mode: mode),
          );
          break;
        case IdentitySortField.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.createdAt, mode: mode),
          );
          break;
        case IdentitySortField.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.modifiedAt, mode: mode),
          );
          break;
        case IdentitySortField.lastUsedAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode),
          );
          break;
        case IdentitySortField.usedCount:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.usedCount, mode: mode),
          );
          break;
        case IdentitySortField.recentScore:
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

      final cardDto = IdentityCardDto(
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
        identity: IdentityCardDataDto(
          displayName: row.read(identityItems.displayName),
          username: row.read(identityItems.username),
          email: row.read(identityItems.email),
          phone: row.read(identityItems.phone),
          company: row.read(identityItems.company),
          hasTaxId: row.read(hasTaxIdExpr) ?? false,
          hasNationalId: row.read(hasNationalIdExpr) ?? false,
          hasPassportNumber: row.read(hasPassportNumberExpr) ?? false,
          hasDriverLicenseNumber: row.read(hasDriverLicenseNumberExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(IdentityFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query =
        selectOnly(vaultItems).join([
            innerJoin(
              identityItems,
              identityItems.itemId.equalsExp(vaultItems.id),
            ),
          ])
          ..addColumns([countExp])
          ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(IdentityFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(
      VaultItemType.identity,
    );

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
      final textExpr =
          vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          identityItems.firstName.like(q) |
          identityItems.lastName.like(q) |
          identityItems.displayName.like(q) |
          identityItems.username.like(q) |
          identityItems.email.like(q) |
          identityItems.company.like(q);
      whereExpr &= textExpr;
    }

    return whereExpr;
  }
}
