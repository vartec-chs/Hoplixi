import 'package:drift/drift.dart';

import 'vault_items.dart';

@DataClassName('SshKeyItemsData')
class SshKeyItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get publicKey => text()();

  TextColumn get privateKey => text()();

  TextColumn get keyType => text().nullable()();

  IntColumn get keySize => integer().nullable()();

  TextColumn get passphraseHint => text().nullable()();

  TextColumn get comment => text().nullable()();

  TextColumn get fingerprint => text().nullable()();

  TextColumn get createdBy => text().nullable()();

  BoolColumn get addedToAgent => boolean().withDefault(const Constant(false))();

  TextColumn get usage => text().nullable()();

  TextColumn get publicKeyFileId => text().nullable()();

  TextColumn get privateKeyFileId => text().nullable()();

  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'ssh_key_items';
}
