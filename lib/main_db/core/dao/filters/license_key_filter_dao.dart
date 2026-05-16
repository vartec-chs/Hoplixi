import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/license_key/license_key_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'license_key_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  LicenseKeyItems,
  Categories,
  Tags,
  ItemTags,
])
class LicenseKeyFilterDao extends DatabaseAccessor<MainStore>
    with _$LicenseKeyFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<LicenseKeyFilter, FilteredCardDto<LicenseKeyCardDto>> {
  LicenseKeyFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<LicenseKeyCardDto>>> getFiltered(
    LicenseKeyFilter filter,
  ) async {
    final whereExpr = _buildWhere(filter);
    final hasKeyExpr = licenseKeyItems.licenseKey.isNotNull();

    final query = selectOnly(vaultItems).join([
      innerJoin(
          licenseKeyItems, licenseKeyItems.itemId.equalsExp(vaultItems.id)),
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
        licenseKeyItems.productName,
        licenseKeyItems.vendor,
        licenseKeyItems.licenseType,
        licenseKeyItems.accountEmail,
        licenseKeyItems.accountUsername,
        licenseKeyItems.validTo,
        hasKeyExpr,
      ])
      ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case LicenseKeySortField.name:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case LicenseKeySortField.productName:
          orderingTerms.add(OrderingTerm(
              expression: licenseKeyItems.productName, mode: mode));
          break;
        case LicenseKeySortField.vendor:
          orderingTerms.add(
              OrderingTerm(expression: licenseKeyItems.vendor, mode: mode));
          break;
        case LicenseKeySortField.licenseType:
          orderingTerms.add(OrderingTerm(
              expression: licenseKeyItems.licenseType, mode: mode));
          break;
        case LicenseKeySortField.purchaseDate:
          orderingTerms.add(OrderingTerm(
              expression: licenseKeyItems.purchaseDate, mode: mode));
          break;
        case LicenseKeySortField.validTo:
          orderingTerms.add(
              OrderingTerm(expression: licenseKeyItems.validTo, mode: mode));
          break;
        case LicenseKeySortField.renewalDate:
          orderingTerms.add(OrderingTerm(
              expression: licenseKeyItems.renewalDate, mode: mode));
          break;
        case LicenseKeySortField.createdAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case LicenseKeySortField.modifiedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case LicenseKeySortField.lastUsedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case LicenseKeySortField.usedCount:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case LicenseKeySortField.recentScore:
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

      final cardDto = LicenseKeyCardDto(
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
        licenseKey: LicenseKeyCardDataDto(
          productName: row.read(licenseKeyItems.productName)!,
          vendor: row.read(licenseKeyItems.vendor),
          licenseType: row.readWithConverter<LicenseType?, String>(
              licenseKeyItems.licenseType),
          accountEmail: row.read(licenseKeyItems.accountEmail),
          accountUsername: row.read(licenseKeyItems.accountUsername),
          validTo: row.read(licenseKeyItems.validTo),
          hasKey: row.read(hasKeyExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(LicenseKeyFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query = selectOnly(vaultItems).join([
      innerJoin(
          licenseKeyItems, licenseKeyItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..addColumns([countExp])
      ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(LicenseKeyFilter filter) {
    Expression<bool> whereExpr =
        vaultItems.type.equalsValue(VaultItemType.licenseKey);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.productName != null) {
      whereExpr &= licenseKeyItems.productName.contains(filter.productName!);
    }
    if (filter.vendor != null) {
      whereExpr &= licenseKeyItems.vendor.contains(filter.vendor!);
    }
    if (filter.licenseType != null) {
      whereExpr &= licenseKeyItems.licenseType.equalsValue(filter.licenseType!);
    }
    if (filter.accountEmail != null) {
      whereExpr &= licenseKeyItems.accountEmail.contains(filter.accountEmail!);
    }
    if (filter.accountUsername != null) {
      whereExpr &=
          licenseKeyItems.accountUsername.contains(filter.accountUsername!);
    }
    if (filter.purchaseEmail != null) {
      whereExpr &=
          licenseKeyItems.purchaseEmail.contains(filter.purchaseEmail!);
    }
    if (filter.orderNumber != null) {
      whereExpr &= licenseKeyItems.orderNumber.contains(filter.orderNumber!);
    }

    if (filter.purchaseDateAfter != null) {
      whereExpr &= licenseKeyItems.purchaseDate
          .isBiggerOrEqualValue(filter.purchaseDateAfter!);
    }
    if (filter.purchaseDateBefore != null) {
      whereExpr &= licenseKeyItems.purchaseDate
          .isSmallerOrEqualValue(filter.purchaseDateBefore!);
    }
    if (filter.validFromAfter != null) {
      whereExpr &= licenseKeyItems.validFrom
          .isBiggerOrEqualValue(filter.validFromAfter!);
    }
    if (filter.validToBefore != null) {
      whereExpr &= licenseKeyItems.validTo
          .isSmallerOrEqualValue(filter.validToBefore!);
    }
    if (filter.renewalDateBefore != null) {
      whereExpr &= licenseKeyItems.renewalDate
          .isSmallerOrEqualValue(filter.renewalDateBefore!);
    }

    if (filter.hasExpiration != null) {
      if (filter.hasExpiration!) {
        whereExpr &= licenseKeyItems.validTo.isNotNull();
      } else {
        whereExpr &= licenseKeyItems.validTo.isNull();
      }
    }
    if (filter.hasRenewal != null) {
      if (filter.hasRenewal!) {
        whereExpr &= licenseKeyItems.renewalDate.isNotNull();
      } else {
        whereExpr &= licenseKeyItems.renewalDate.isNull();
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          licenseKeyItems.productName.like(q) |
          licenseKeyItems.vendor.like(q) |
          licenseKeyItems.accountEmail.like(q);
      whereExpr &= textExpr;
    }

    return whereExpr;
  }
}
