import 'package:drift/drift.dart';

import 'vault_items.dart';

@DataClassName('WifiItemsData')
class WifiItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get ssid => text()();

  TextColumn get password => text().nullable()();

  TextColumn get security => text().nullable()();

  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  TextColumn get eapMethod => text().nullable()();

  TextColumn get username => text().nullable()();

  TextColumn get identity => text().nullable()();

  TextColumn get domain => text().nullable()();

  TextColumn get lastConnectedBssid => text().nullable()();

  IntColumn get priority => integer().nullable()();

  TextColumn get qrCodePayload => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'wifi_items';
}
