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
    final query = _buildQuery(filter);
    applyLimitOffset(query, filter.base);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final categoryIds =
        rows.map((r) => r.readTable(vaultItems).categoryId).whereType<String>().toList();

    final categoriesMap = await loadCategoriesForItems(categoryIds);
    final tagsMap = await loadTagsForItems(itemIds);

    final hasPasswordExpr = db.wifiItems.password.isNotNull();

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final wifi = row.readTable(wifiItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = WifiCardDto(
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
        wifi: WifiCardDataDto(
          ssid: wifi.ssid,
          securityType: row.readWithConverter<WifiSecurityType?, String>(wifiItems.securityType),
          encryption: row.readWithConverter<WifiEncryptionType?, String>(wifiItems.encryption),
          hiddenSsid: wifi.hiddenSsid,
          hasWifiPassword: row.read(hasPasswordExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(WifiFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(WifiFilter filter) {
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

    final hasPasswordExpr = db.wifiItems.password.isNotNull();

    final query = select(vaultItems).join([
      innerJoin(wifiItems, wifiItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..where(whereExpr)
      ..addColumns([hasPasswordExpr]);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case WifiSortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case WifiSortField.ssid:
          orderingTerms.add(OrderingTerm(expression: wifiItems.ssid, mode: mode));
          break;
        case WifiSortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case WifiSortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case WifiSortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case WifiSortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case WifiSortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
