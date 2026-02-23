import 'package:drift/drift.dart';

import 'vault_items.dart';

@DataClassName('IdentityItemsData')
class IdentityItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get idType => text()();

  TextColumn get idNumber => text()();

  TextColumn get fullName => text().nullable()();

  DateTimeColumn get dateOfBirth => dateTime().nullable()();

  TextColumn get placeOfBirth => text().nullable()();

  TextColumn get nationality => text().nullable()();

  TextColumn get issuingAuthority => text().nullable()();

  DateTimeColumn get issueDate => dateTime().nullable()();

  DateTimeColumn get expiryDate => dateTime().nullable()();

  TextColumn get mrz => text().nullable()();

  TextColumn get scanAttachmentId => text().nullable()();

  TextColumn get photoAttachmentId => text().nullable()();

  BoolColumn get verified => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'identity_items';
}
