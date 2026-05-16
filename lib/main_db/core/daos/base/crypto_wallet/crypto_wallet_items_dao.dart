import 'package:drift/drift.dart';

import '../../../main_store.dart';
import '../../../tables/crypto_wallet/crypto_wallet_items.dart';

part 'crypto_wallet_items_dao.g.dart';

@DriftAccessor(tables: [CryptoWalletItems])
class CryptoWalletItemsDao extends DatabaseAccessor<MainStore>
    with _$CryptoWalletItemsDaoMixin {
  CryptoWalletItemsDao(super.db);

  Future<void> insertCryptoWallet(CryptoWalletItemsCompanion companion) {
    return into(cryptoWalletItems).insert(companion);
  }

  Future<int> updateCryptoWalletByItemId(
    String itemId,
    CryptoWalletItemsCompanion companion,
  ) {
    return (update(cryptoWalletItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<CryptoWalletItemsData?> getCryptoWalletByItemId(String itemId) {
    return (select(cryptoWalletItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsCryptoWalletByItemId(String itemId) async {
    final row = await (selectOnly(cryptoWalletItems)
          ..addColumns([cryptoWalletItems.itemId])
          ..where(cryptoWalletItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteCryptoWalletByItemId(String itemId) {
    return (delete(cryptoWalletItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .go();
  }

  Future<String?> getMnemonicByItemId(String itemId) async {
    final row = await (selectOnly(cryptoWalletItems)
          ..addColumns([cryptoWalletItems.mnemonic])
          ..where(cryptoWalletItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(cryptoWalletItems.mnemonic);
  }

  Future<String?> getPrivateKeyByItemId(String itemId) async {
    final row = await (selectOnly(cryptoWalletItems)
          ..addColumns([cryptoWalletItems.privateKey])
          ..where(cryptoWalletItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(cryptoWalletItems.privateKey);
  }

  Future<String?> getXprvByItemId(String itemId) async {
    final row = await (selectOnly(cryptoWalletItems)
          ..addColumns([cryptoWalletItems.xprv])
          ..where(cryptoWalletItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(cryptoWalletItems.xprv);
  }
}
