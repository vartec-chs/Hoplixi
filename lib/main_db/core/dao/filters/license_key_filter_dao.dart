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
    final query = _buildQuery(filter);
    applyLimitOffset(query, filter.base);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final categoryIds =
        rows.map((r) => r.readTable(vaultItems).categoryId).whereType<String>().toList();

    final categoriesMap = await loadCategoriesForItems(categoryIds);
    final tagsMap = await loadTagsForItems(itemIds);

    final hasKeyExpr = db.licenseKeyItems.licenseKey.isNotNull();

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final lk = row.readTable(licenseKeyItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = LicenseKeyCardDto(
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
        licenseKey: LicenseKeyCardDataDto(
          productName: lk.productName,
          vendor: lk.vendor,
          licenseType: row.readWithConverter<LicenseType?, String>(licenseKeyItems.licenseType),
          accountEmail: lk.accountEmail,
          accountUsername: lk.accountUsername,
          validTo: lk.validTo,
          hasKey: row.read(hasKeyExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(LicenseKeyFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(LicenseKeyFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.licenseKey);

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
      whereExpr &= licenseKeyItems.accountUsername.contains(filter.accountUsername!);
    }
    if (filter.purchaseEmail != null) {
      whereExpr &= licenseKeyItems.purchaseEmail.contains(filter.purchaseEmail!);
    }
    if (filter.orderNumber != null) {
      whereExpr &= licenseKeyItems.orderNumber.contains(filter.orderNumber!);
    }

    if (filter.purchaseDateAfter != null) {
      whereExpr &= licenseKeyItems.purchaseDate.isBiggerOrEqualValue(filter.purchaseDateAfter!);
    }
    if (filter.purchaseDateBefore != null) {
      whereExpr &= licenseKeyItems.purchaseDate.isSmallerOrEqualValue(filter.purchaseDateBefore!);
    }
    if (filter.validFromAfter != null) {
      whereExpr &= licenseKeyItems.validFrom.isBiggerOrEqualValue(filter.validFromAfter!);
    }
    if (filter.validToBefore != null) {
      whereExpr &= licenseKeyItems.validTo.isSmallerOrEqualValue(filter.validToBefore!);
    }
    if (filter.renewalDateBefore != null) {
      whereExpr &= licenseKeyItems.renewalDate.isSmallerOrEqualValue(filter.renewalDateBefore!);
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

    final hasKeyExpr = db.licenseKeyItems.licenseKey.isNotNull();

    final query = select(vaultItems).join([
      innerJoin(licenseKeyItems, licenseKeyItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..where(whereExpr)
      ..addColumns([hasKeyExpr]);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case LicenseKeySortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case LicenseKeySortField.productName:
          orderingTerms.add(OrderingTerm(expression: licenseKeyItems.productName, mode: mode));
          break;
        case LicenseKeySortField.vendor:
          orderingTerms.add(OrderingTerm(expression: licenseKeyItems.vendor, mode: mode));
          break;
        case LicenseKeySortField.licenseType:
          orderingTerms.add(OrderingTerm(expression: licenseKeyItems.licenseType, mode: mode));
          break;
        case LicenseKeySortField.purchaseDate:
          orderingTerms.add(OrderingTerm(expression: licenseKeyItems.purchaseDate, mode: mode));
          break;
        case LicenseKeySortField.validTo:
          orderingTerms.add(OrderingTerm(expression: licenseKeyItems.validTo, mode: mode));
          break;
        case LicenseKeySortField.renewalDate:
          orderingTerms.add(OrderingTerm(expression: licenseKeyItems.renewalDate, mode: mode));
          break;
        case LicenseKeySortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case LicenseKeySortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case LicenseKeySortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case LicenseKeySortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case LicenseKeySortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
