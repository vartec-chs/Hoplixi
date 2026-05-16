import 'package:drift/drift.dart';

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
}
