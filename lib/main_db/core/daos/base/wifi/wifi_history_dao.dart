import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

import '../../../main_store.dart';
import '../../../tables/wifi/wifi_history.dart';

part 'wifi_history_dao.g.dart';

@DriftAccessor(tables: [WifiHistory])
class WifiHistoryDao extends DatabaseAccessor<MainStore>
    with _$WifiHistoryDaoMixin {
  WifiHistoryDao(super.db);

  Future<void> insertWifiHistory(WifiHistoryCompanion companion) {
    return into(wifiHistory).insert(companion);
  }

  Future<WifiHistoryData?> getWifiHistoryByHistoryId(String historyId) {
    return (select(wifiHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsWifiHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(wifiHistory)
          ..addColumns([wifiHistory.historyId])
          ..where(wifiHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteWifiHistoryByHistoryId(String historyId) {
    return (delete(wifiHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }


  // --- HISTORY CARD BATCH METHODS ---
  Future<List<WifiHistoryData>> getWifiHistoryByHistoryIds(List<String> historyIds) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(wifiHistory)..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, WifiHistoryCardDataDto>> getWifiHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final hasPasswordExpr = wifiHistory.password.isNotNull();
    final query = selectOnly(wifiHistory)
      ..addColumns([
        wifiHistory.historyId,
        wifiHistory.ssid,
        wifiHistory.securityType,
        wifiHistory.encryption,
        wifiHistory.hiddenSsid,
        hasPasswordExpr,
      ])
      ..where(wifiHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(wifiHistory.historyId)!: WifiHistoryCardDataDto(
          ssid: row.read(wifiHistory.ssid),
          securityType: row.readWithConverter<WifiSecurityType?, String>(wifiHistory.securityType),
          encryption: row.readWithConverter<WifiEncryptionType?, String>(wifiHistory.encryption),
          hiddenSsid: row.read(wifiHistory.hiddenSsid),
          hasPassword: row.read(hasPasswordExpr) ?? false,
        ),
    };
  }

  Future<String?> getPasswordByHistoryId(String historyId) async {
    final row = await (selectOnly(wifiHistory)
          ..addColumns([wifiHistory.password])
          ..where(wifiHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(wifiHistory.password);
  }

}
