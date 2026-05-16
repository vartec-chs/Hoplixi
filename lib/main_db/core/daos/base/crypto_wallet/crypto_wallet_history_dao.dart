import 'package:drift/drift.dart';

import '../../../main_store.dart';
import '../../../tables/crypto_wallet/crypto_wallet_history.dart';

part 'crypto_wallet_history_dao.g.dart';

@DriftAccessor(tables: [CryptoWalletHistory])
class CryptoWalletHistoryDao extends DatabaseAccessor<MainStore>
    with _$CryptoWalletHistoryDaoMixin {
  CryptoWalletHistoryDao(super.db);

  Future<void> insertCryptoWalletHistory(CryptoWalletHistoryCompanion companion) {
    return into(cryptoWalletHistory).insert(companion);
  }

  Future<CryptoWalletHistoryData?> getCryptoWalletHistoryByHistoryId(
      String historyId) {
    return (select(cryptoWalletHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsCryptoWalletHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(cryptoWalletHistory)
          ..addColumns([cryptoWalletHistory.historyId])
          ..where(cryptoWalletHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteCryptoWalletHistoryByHistoryId(String historyId) {
    return (delete(cryptoWalletHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }
}
