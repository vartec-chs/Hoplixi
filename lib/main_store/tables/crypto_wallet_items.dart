import 'package:drift/drift.dart';

import 'vault_items.dart';

@DataClassName('CryptoWalletItemsData')
class CryptoWalletItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

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

  BoolColumn get watchOnly => boolean().withDefault(const Constant(false))();

  TextColumn get derivationScheme => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'crypto_wallet_items';
}
