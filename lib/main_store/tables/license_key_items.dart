import 'package:drift/drift.dart';

import 'vault_items.dart';

@DataClassName('LicenseKeyItemsData')
class LicenseKeyItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get product => text()();

  TextColumn get licenseKey => text()();

  TextColumn get licenseType => text().nullable()();

  IntColumn get seats => integer().nullable()();

  IntColumn get maxActivations => integer().nullable()();

  DateTimeColumn get activatedOn => dateTime().nullable()();

  DateTimeColumn get purchaseDate => dateTime().nullable()();

  TextColumn get purchaseFrom => text().nullable()();

  TextColumn get orderId => text().nullable()();

  TextColumn get licenseFileId => text().nullable()();

  DateTimeColumn get expiresAt => dateTime().nullable()();

  TextColumn get licenseNotes => text().nullable()();

  TextColumn get supportContact => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'license_key_items';
}
