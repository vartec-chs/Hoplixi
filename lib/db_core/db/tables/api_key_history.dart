import 'package:drift/drift.dart';

import 'vault_item_history.dart';

@DataClassName('ApiKeyHistoryData')
class ApiKeyHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  TextColumn get service => text().withLength(min: 1, max: 255)();

  TextColumn get key => text().nullable()();

  TextColumn get maskedKey => text().nullable()();

  TextColumn get tokenType => text().nullable()();

  TextColumn get environment => text().nullable()();

  DateTimeColumn get expiresAt => dateTime().nullable()();

  BoolColumn get revoked => boolean().withDefault(const Constant(false))();

  IntColumn get rotationPeriodDays => integer().nullable()();

  DateTimeColumn get lastRotatedAt => dateTime().nullable()();

  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'api_key_history';
}
