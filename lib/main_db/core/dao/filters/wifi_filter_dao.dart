import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import '../../tables/wifi/wifi_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'wifi_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  WifiItems,
  Categories,
  Tags,
  ItemTags,
])
class WifiFilterDao extends DatabaseAccessor<MainStore>
    with _$WifiFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<WifiFilter, FilteredCardDto<WifiCardDto>> {
  WifiFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<WifiCardDto>>> getFiltered(
    WifiFilter filter,
  ) async {
    final whereExpr = _buildWhere(filter);
    final hasPasswordExpr = wifiItems.password.isNotNull();

    final query = selectOnly(vaultItems).join([
      innerJoin(wifiItems, wifiItems.itemId.equalsExp(vaultItems.id)),
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
        wifiItems.ssid,
        wifiItems.securityType,
        wifiItems.encryption,
        wifiItems.hiddenSsid,
        hasPasswordExpr,
      ])
      ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case WifiSortField.name:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case WifiSortField.ssid:
          orderingTerms.add(
              OrderingTerm(expression: wifiItems.ssid, mode: mode));
          break;
        case WifiSortField.createdAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case WifiSortField.modifiedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case WifiSortField.lastUsedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case WifiSortField.usedCount:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case WifiSortField.recentScore:
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

      final cardDto = WifiCardDto(
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
        wifi: WifiCardDataDto(
          ssid: row.read(wifiItems.ssid)!,
          securityType: row.readWithConverter<WifiSecurityType?, String>(
              wifiItems.securityType),
          encryption: row.readWithConverter<WifiEncryptionType?, String>(
              wifiItems.encryption),
          hiddenSsid: row.read(wifiItems.hiddenSsid) ?? false,
          hasWifiPassword: row.read(hasPasswordExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(WifiFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query = selectOnly(vaultItems).join([
      innerJoin(wifiItems, wifiItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..addColumns([countExp])
      ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(WifiFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.wifi);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.ssid != null) {
      whereExpr &= wifiItems.ssid.contains(filter.ssid!);
    }
    if (filter.securityType != null) {
      whereExpr &= wifiItems.securityType.equalsValue(filter.securityType!);
    }
    if (filter.encryption != null) {
      whereExpr &= wifiItems.encryption.equalsValue(filter.encryption!);
    }
    if (filter.hiddenSsid != null) {
      whereExpr &= wifiItems.hiddenSsid.equals(filter.hiddenSsid!);
    }
    if (filter.hasPassword != null) {
      if (filter.hasPassword!) {
        whereExpr &= wifiItems.password.isNotNull();
      } else {
        whereExpr &= wifiItems.password.isNull();
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          wifiItems.ssid.like(q);
      whereExpr &= textExpr;
    }

    return whereExpr;
  }
}
