import 'package:drift/drift.dart';

import 'vault_item_history.dart';

@DataClassName('CryptoWalletHistoryData')
class CryptoWalletHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  TextColumn get walletType => text()();

  TextColumn get mnemonic => text().nullable()();

  TextColumn get privateKey => text().nullable()();

  TextColumn get derivationPath => text().nullable()();

  TextColumn get network => text().nullable()();

  TextColumn get addresses => text().nullable()();

  TextColumn get xpub => text().nullable()();

  TextColumn get xprv => text().nullable()();

  TextColumn get hardwareDevice => text().nullable()();

  DateTimeColumn get lastBalanceCheckedAt => dateTime().nullable()();

  TextColumn get notesOnUsage => text().nullable()();

  BoolColumn get watchOnly => boolean().withDefault(const Constant(false))();

  TextColumn get derivationScheme => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'crypto_wallet_history';
}
