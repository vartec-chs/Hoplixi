import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/dto/wifi_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/wifis_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:hoplixi/main_store/tables/wifi_items.dart';

part 'wifi_filter_dao.g.dart';

@DriftAccessor(
  tables: [VaultItems, WifiItems, Categories, Tags, ItemTags, NoteItems],
)
class WifiFilterDao extends DatabaseAccessor<MainStore>
    with _$WifiFilterDaoMixin
    implements FilterDao<WifisFilter, WifiCardDto> {
  WifiFilterDao(super.db);

  @override
  Future<List<WifiCardDto>> getFiltered(WifisFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(wifiItems, wifiItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(categories, categories.id.equalsExp(vaultItems.categoryId)),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    query.orderBy(_buildOrderBy(filter));

    if (filter.base.limit != null && filter.base.limit! > 0) {
      query.limit(filter.base.limit!, offset: filter.base.offset);
    }

    final rows = await query.get();
    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final tagsMap = await _loadTagsForItems(itemIds);

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final wifi = row.readTable(wifiItems);
      final category = row.readTableOrNull(categories);

      return WifiCardDto(
        id: item.id,
        name: item.name,
        ssid: wifi.ssid,
        security: wifi.security,
        hidden: wifi.hidden,
        eapMethod: wifi.eapMethod,
        priority: wifi.priority,
        lastConnectedBssid: wifi.lastConnectedBssid,
        hasPassword: wifi.password != null && wifi.password!.isNotEmpty,
        description: item.description,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        tags: tagsMap[item.id] ?? [],
        isFavorite: item.isFavorite,
        isPinned: item.isPinned,
        isArchived: item.isArchived,
        isDeleted: item.isDeleted,
        usedCount: item.usedCount,
        modifiedAt: item.modifiedAt,
        createdAt: item.createdAt,
      );
    }).toList();
  }

  @override
  Future<int> countFiltered(WifisFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(wifiItems, wifiItems.itemId.equalsExp(vaultItems.id)),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    final rows = await query.get();
    return rows.length;
  }

  Expression<bool> _buildWhereExpression(WifisFilter filter) {
    Expression<bool> expr = const Constant(true);
    expr = expr & _applyBaseFilters(filter.base);
    expr = expr & _applySpecificFilters(filter);
    return expr;
  }

  Expression<bool> _applyBaseFilters(BaseFilter base) {
    Expression<bool> expr = const Constant(true);

    if (base.isDeleted == null) {
      expr = expr & vaultItems.isDeleted.equals(false);
    }

    if (base.query.isNotEmpty) {
      final q = base.query.toLowerCase();
      expr =
          expr &
          (vaultItems.name.lower().like('%$q%') |
              wifiItems.ssid.lower().like('%$q%') |
              wifiItems.security.lower().like('%$q%') |
              wifiItems.eapMethod.lower().like('%$q%') |
              wifiItems.lastConnectedBssid.lower().like('%$q%') |
              vaultItems.description.lower().like('%$q%') |
              noteItems.content.lower().like('%$q%'));
    }

    if (base.categoryIds.isNotEmpty) {
      expr = expr & vaultItems.categoryId.isIn(base.categoryIds);
    }

    if (base.tagIds.isNotEmpty) {
      final tagExists = existsQuery(
        select(itemTags)..where(
          (t) => t.itemId.equalsExp(vaultItems.id) & t.tagId.isIn(base.tagIds),
        ),
      );
      expr = expr & tagExists;
    }

    if (base.isFavorite != null) {
      expr = expr & vaultItems.isFavorite.equals(base.isFavorite!);
    }

    if (base.isArchived != null) {
      expr = expr & vaultItems.isArchived.equals(base.isArchived!);
    } else {
      expr = expr & vaultItems.isArchived.equals(false);
    }

    if (base.isDeleted != null) {
      expr = expr & vaultItems.isDeleted.equals(base.isDeleted!);
    }

    return expr;
  }

  Expression<bool> _applySpecificFilters(WifisFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.name != null) {
      expr =
          expr &
          vaultItems.name.lower().like('%${filter.name!.toLowerCase()}%');
    }

    if (filter.ssid != null) {
      expr =
          expr & wifiItems.ssid.lower().like('%${filter.ssid!.toLowerCase()}%');
    }

    if (filter.security != null) {
      expr =
          expr &
          wifiItems.security.lower().like(
            '%${filter.security!.toLowerCase()}%',
          );
    }

    if (filter.eapMethod != null) {
      expr =
          expr &
          wifiItems.eapMethod.lower().like(
            '%${filter.eapMethod!.toLowerCase()}%',
          );
    }

    if (filter.hidden != null) {
      expr = expr & wifiItems.hidden.equals(filter.hidden!);
    }

    if (filter.hasPassword != null) {
      expr =
          expr &
          (filter.hasPassword!
              ? (wifiItems.password.isNotNull() &
                    wifiItems.password.isBiggerThanValue(''))
              : (wifiItems.password.isNull() | wifiItems.password.equals('')));
    }

    if (filter.isOpenNetwork != null) {
      expr =
          expr &
          (filter.isOpenNetwork!
              ? (wifiItems.security.isNull() |
                    wifiItems.security.lower().equals('open'))
              : (wifiItems.security.isNotNull() &
                    wifiItems.security
                        .lower()
                        .equalsExp(const Constant('open'))
                        .not()));
    }

    return expr;
  }

  List<OrderingTerm> _buildOrderBy(WifisFilter filter) {
    final terms = <OrderingTerm>[
      OrderingTerm(expression: vaultItems.isPinned, mode: OrderingMode.desc),
    ];

    final mode = filter.base.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    switch (filter.sortField) {
      case WifisSortField.name:
        terms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
      case WifisSortField.ssid:
        terms.add(OrderingTerm(expression: wifiItems.ssid, mode: mode));
      case WifisSortField.priority:
        terms.add(OrderingTerm(expression: wifiItems.priority, mode: mode));
      case WifisSortField.createdAt:
        terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
      case WifisSortField.modifiedAt:
        terms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
      case WifisSortField.lastAccessed:
        terms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
      case null:
        terms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
    }

    return terms;
  }

  Future<Map<String, List<TagInCardDto>>> _loadTagsForItems(
    List<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return {};

    final query = select(itemTags).join([
      innerJoin(tags, tags.id.equalsExp(itemTags.tagId)),
    ])..where(itemTags.itemId.isIn(itemIds));

    final rows = await query.get();
    final tagsMap = <String, List<TagInCardDto>>{};

    for (final row in rows) {
      final it = row.readTable(itemTags);
      final tag = row.readTable(tags);
      final list = tagsMap.putIfAbsent(it.itemId, () => []);
      if (list.length < 10) {
        list.add(TagInCardDto(id: tag.id, name: tag.name, color: tag.color));
      }
    }

    return tagsMap;
  }
}
