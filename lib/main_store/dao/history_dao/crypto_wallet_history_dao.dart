import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/crypto_wallet_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/crypto_wallet_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'crypto_wallet_history_dao.g.dart';

@DriftAccessor(tables: [VaultItemHistory, CryptoWalletHistory])
class CryptoWalletHistoryDao extends DatabaseAccessor<MainStore>
    with _$CryptoWalletHistoryDaoMixin {
  CryptoWalletHistoryDao(super.db);

  Future<List<CryptoWalletHistoryCardDto>>
  getCryptoWalletHistoryCardsByOriginalId(
    String cryptoWalletId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        cryptoWalletHistory,
        cryptoWalletHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(cryptoWalletId) &
        vaultItemHistory.type.equalsValue(VaultItemType.cryptoWallet);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              cryptoWalletHistory.walletType.like(q) |
              cryptoWalletHistory.network.like(q) |
              cryptoWalletHistory.hardwareDevice.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapToCard).toList();
  }

  Future<int> countCryptoWalletHistoryByOriginalId(
    String cryptoWalletId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();

    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          cryptoWalletHistory,
          cryptoWalletHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(cryptoWalletId) &
            vaultItemHistory.type.equalsValue(VaultItemType.cryptoWallet),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            cryptoWalletHistory.walletType.like(q) |
            cryptoWalletHistory.network.like(q) |
            cryptoWalletHistory.hardwareDevice.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  Future<int> deleteCryptoWalletHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  Future<int> deleteCryptoWalletHistoryByCryptoWalletId(String cryptoWalletId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(cryptoWalletId) &
              h.type.equalsValue(VaultItemType.cryptoWallet),
        ))
        .go();
  }

  CryptoWalletHistoryCardDto _mapToCard(TypedResult row) {
    final history = row.readTable(vaultItemHistory);
    final wallet = row.readTable(cryptoWalletHistory);

    return CryptoWalletHistoryCardDto(
      id: history.id,
      originalCryptoWalletId: history.itemId,
      action: history.action.value,
      name: history.name,
      walletType: wallet.walletType,
      network: wallet.network,
      watchOnly: wallet.watchOnly,
      lastBalanceCheckedAt: wallet.lastBalanceCheckedAt,
      actionAt: history.actionAt,
    );
  }
}
