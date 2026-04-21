import 'package:drift/drift.dart';

import 'vault_items.dart';

@DataClassName('ApiKeyItemsData')
class ApiKeyItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get service => text().withLength(min: 1, max: 255)();

  TextColumn get key => text()();

  TextColumn get maskedKey => text().nullable()();

  TextColumn get tokenType => text().nullable()();

  TextColumn get environment => text().nullable()();

  DateTimeColumn get expiresAt => dateTime().nullable()();

  BoolColumn get revoked => boolean().withDefault(const Constant(false))();

  IntColumn get rotationPeriodDays => integer().nullable()();

  DateTimeColumn get lastRotatedAt => dateTime().nullable()();

  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'api_key_items';
}
