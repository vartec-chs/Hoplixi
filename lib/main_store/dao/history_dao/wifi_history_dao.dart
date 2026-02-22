import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/wifi_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';
import 'package:hoplixi/main_store/tables/wifi_history.dart';

part 'wifi_history_dao.g.dart';

@DriftAccessor(tables: [VaultItemHistory, WifiHistory])
class WifiHistoryDao extends DatabaseAccessor<MainStore>
    with _$WifiHistoryDaoMixin {
  WifiHistoryDao(super.db);

  Future<List<WifiHistoryCardDto>> getWifiHistoryCardsByOriginalId(
    String wifiId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        wifiHistory,
        wifiHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(wifiId) &
        vaultItemHistory.type.equalsValue(VaultItemType.wifi);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              wifiHistory.ssid.like(q) |
              wifiHistory.security.like(q) |
              wifiHistory.lastConnectedBssid.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapToCard).toList();
  }

  Future<int> countWifiHistoryByOriginalId(
    String wifiId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();

    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          wifiHistory,
          wifiHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(wifiId) &
            vaultItemHistory.type.equalsValue(VaultItemType.wifi),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            wifiHistory.ssid.like(q) |
            wifiHistory.security.like(q) |
            wifiHistory.lastConnectedBssid.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  Future<int> deleteWifiHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  Future<int> deleteWifiHistoryByWifiId(String wifiId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(wifiId) & h.type.equalsValue(VaultItemType.wifi),
        ))
        .go();
  }

  WifiHistoryCardDto _mapToCard(TypedResult row) {
    final history = row.readTable(vaultItemHistory);
    final wifi = row.readTable(wifiHistory);

    return WifiHistoryCardDto(
      id: history.id,
      originalWifiId: history.itemId,
      action: history.action.value,
      name: history.name,
      ssid: wifi.ssid,
      security: wifi.security,
      hidden: wifi.hidden,
      priority: wifi.priority,
      actionAt: history.actionAt,
    );
  }
}
