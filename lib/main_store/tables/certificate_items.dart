import 'package:drift/drift.dart';

import 'vault_items.dart';

@DataClassName('CertificateItemsData')
class CertificateItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get certificatePem => text()();

  TextColumn get privateKey => text().nullable()();

  TextColumn get serialNumber => text().nullable()();

  TextColumn get issuer => text().nullable()();

  TextColumn get subject => text().nullable()();

  DateTimeColumn get validFrom => dateTime().nullable()();

  DateTimeColumn get validTo => dateTime().nullable()();

  TextColumn get fingerprint => text().nullable()();

  TextColumn get keyUsage => text().nullable()();

  TextColumn get extensions => text().nullable()();

  BlobColumn get pfxBlob => blob().nullable()();

  TextColumn get passwordForPfx => text().nullable()();

  TextColumn get ocspUrl => text().nullable()();

  TextColumn get crlUrl => text().nullable()();

  BoolColumn get autoRenew => boolean().withDefault(const Constant(false))();

  DateTimeColumn get lastCheckedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'certificate_items';
}
