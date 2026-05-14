import 'package:drift/drift.dart';

import '../main_store.dart';
import '../tables/wifi/wifi_items.dart';

part 'wifi_items_dao.g.dart';

@DriftAccessor(tables: [WifiItems])
class WifiItemsDao extends DatabaseAccessor<MainStore> with _$WifiItemsDaoMixin {
  WifiItemsDao(super.db);

  Future<void> insertWifi(WifiItemsCompanion companion) {
    return into(wifiItems).insert(companion);
  }

  Future<int> updateWifiByItemId(
    String itemId,
    WifiItemsCompanion companion,
  ) {
    return (update(wifiItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<WifiItemsData?> getWifiByItemId(String itemId) {
    return (select(wifiItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsWifiByItemId(String itemId) async {
    final row = await (selectOnly(wifiItems)
          ..addColumns([wifiItems.itemId])
          ..where(wifiItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteWifiByItemId(String itemId) {
    return (delete(wifiItems)..where((tbl) => tbl.itemId.equals(itemId))).go();
  }
}
