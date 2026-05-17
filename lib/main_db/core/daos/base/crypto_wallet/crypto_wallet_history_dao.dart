import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

import '../../../main_store.dart';

part 'crypto_wallet_history_dao.g.dart';

@DriftAccessor(tables: [CryptoWalletHistory])
class CryptoWalletHistoryDao extends DatabaseAccessor<MainStore>
    with _$CryptoWalletHistoryDaoMixin {
  CryptoWalletHistoryDao(super.db);

  Future<void> insertCryptoWalletHistory(
    CryptoWalletHistoryCompanion companion,
  ) {
    return into(cryptoWalletHistory).insert(companion);
  }

  Future<CryptoWalletHistoryData?> getCryptoWalletHistoryByHistoryId(
    String historyId,
  ) {
    return (select(
      cryptoWalletHistory,
    )..where((tbl) => tbl.historyId.equals(historyId))).getSingleOrNull();
  }

  Future<bool> existsCryptoWalletHistoryByHistoryId(String historyId) async {
    final row =
        await (selectOnly(cryptoWalletHistory)
              ..addColumns([cryptoWalletHistory.historyId])
              ..where(cryptoWalletHistory.historyId.equals(historyId)))
            .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteCryptoWalletHistoryByHistoryId(String historyId) {
    return (delete(
      cryptoWalletHistory,
    )..where((tbl) => tbl.historyId.equals(historyId))).go();
  }

  // --- HISTORY CARD BATCH METHODS ---
  Future<List<CryptoWalletHistoryData>> getCryptoWalletHistoryByHistoryIds(
    List<String> historyIds,
  ) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(
      cryptoWalletHistory,
    )..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, CryptoWalletHistoryCardDataDto>>
  getCryptoWalletHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final hasMnemonicExpr = cryptoWalletHistory.mnemonic.isNotNull();
    final hasPrivateKeyExpr = cryptoWalletHistory.privateKey.isNotNull();
    final hasXprvExpr = cryptoWalletHistory.xprv.isNotNull();
    final query = selectOnly(cryptoWalletHistory)
      ..addColumns([
        cryptoWalletHistory.historyId,
        cryptoWalletHistory.walletType,
        cryptoWalletHistory.network,
        cryptoWalletHistory.derivationPath,
        cryptoWalletHistory.derivationScheme,
        cryptoWalletHistory.addresses,
        cryptoWalletHistory.xpub,
        cryptoWalletHistory.hardwareDevice,
        cryptoWalletHistory.watchOnly,
        hasMnemonicExpr,
        hasPrivateKeyExpr,
        hasXprvExpr,
      ])
      ..where(cryptoWalletHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(
          cryptoWalletHistory.historyId,
        )!: CryptoWalletHistoryCardDataDto(
          walletType: row.readWithConverter<CryptoWalletType?, String>(
            cryptoWalletHistory.walletType,
          ),
          network: row.readWithConverter<CryptoNetwork?, String>(
            cryptoWalletHistory.network,
          ),
          derivationPath: row.read(cryptoWalletHistory.derivationPath),
          derivationScheme: row
              .readWithConverter<CryptoDerivationScheme?, String>(
                cryptoWalletHistory.derivationScheme,
              ),
          addresses: row.read(cryptoWalletHistory.addresses),
          xpub: row.read(cryptoWalletHistory.xpub),
          hardwareDevice: row.read(cryptoWalletHistory.hardwareDevice),
          watchOnly: row.read(cryptoWalletHistory.watchOnly),
          hasMnemonic: row.read(hasMnemonicExpr) ?? false,
          hasPrivateKey: row.read(hasPrivateKeyExpr) ?? false,
          hasXprv: row.read(hasXprvExpr) ?? false,
        ),
    };
  }

  Future<String?> getMnemonicByHistoryId(String historyId) async {
    final row =
        await (selectOnly(cryptoWalletHistory)
              ..addColumns([cryptoWalletHistory.mnemonic])
              ..where(cryptoWalletHistory.historyId.equals(historyId)))
            .getSingleOrNull();
    return row?.read(cryptoWalletHistory.mnemonic);
  }

  Future<String?> getPrivateKeyByHistoryId(String historyId) async {
    final row =
        await (selectOnly(cryptoWalletHistory)
              ..addColumns([cryptoWalletHistory.privateKey])
              ..where(cryptoWalletHistory.historyId.equals(historyId)))
            .getSingleOrNull();
    return row?.read(cryptoWalletHistory.privateKey);
  }

  Future<String?> getXprvByHistoryId(String historyId) async {
    final row =
        await (selectOnly(cryptoWalletHistory)
              ..addColumns([cryptoWalletHistory.xprv])
              ..where(cryptoWalletHistory.historyId.equals(historyId)))
            .getSingleOrNull();
    return row?.read(cryptoWalletHistory.xprv);
  }
}
