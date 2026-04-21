import 'package:drift/drift.dart';

import 'vault_item_history.dart';

@DataClassName('SshKeyHistoryData')
class SshKeyHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  TextColumn get publicKey => text()();

  TextColumn get privateKey => text().nullable()();

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
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'ssh_key_history';
}
