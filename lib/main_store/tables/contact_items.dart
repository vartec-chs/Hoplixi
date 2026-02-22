import 'package:drift/drift.dart';

import 'vault_items.dart';

@DataClassName('ContactItemsData')
class ContactItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get phone => text().nullable()();

  TextColumn get email => text().nullable()();

  TextColumn get company => text().nullable()();

  TextColumn get jobTitle => text().nullable()();

  TextColumn get address => text().nullable()();

  TextColumn get website => text().nullable()();

  DateTimeColumn get birthday => dateTime().nullable()();

  BoolColumn get isEmergencyContact =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'contact_items';
}
