import 'package:drift/drift.dart';

import 'vault_item_history.dart';

@DataClassName('WifiHistoryData')
class WifiHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

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

  TextColumn get notes => text().nullable()();

  TextColumn get qrCodePayload => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'wifi_history';
}
