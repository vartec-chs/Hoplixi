import 'package:drift/drift.dart';

import 'vault_item_history.dart';

@DataClassName('CertificateHistoryData')
class CertificateHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

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
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'certificate_history';
}
