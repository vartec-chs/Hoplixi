import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/crypto_wallet_history_payload.dart';
import 'vault_history_restore_handler.dart';

class CryptoWalletHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  CryptoWalletHistoryRestoreHandler({required this.cryptoWalletItemsDao});

  final CryptoWalletItemsDao cryptoWalletItemsDao;

  @override
  VaultItemType get type => VaultItemType.cryptoWallet;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! CryptoWalletHistoryPayload) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for CryptoWallet restore',
          entity: 'cryptoWallet',
        ),
      );
    }

    await cryptoWalletItemsDao.upsertCryptoWalletItem(
      CryptoWalletItemsCompanion(
        itemId: Value(base.itemId),
        walletType: Value(payload.walletType),
        walletTypeOther: Value(payload.walletTypeOther),
        network: Value(payload.network),
        networkOther: Value(payload.networkOther),
        mnemonic: Value(payload.mnemonic),
        privateKey: Value(payload.privateKey),
        derivationPath: Value(payload.derivationPath),
        derivationScheme: Value(payload.derivationScheme),
        derivationSchemeOther: Value(payload.derivationSchemeOther),
        addresses: Value(payload.addresses),
        xpub: Value(payload.xpub),
        xprv: Value(payload.xprv),
        hardwareDevice: Value(payload.hardwareDevice),
        watchOnly: Value(payload.watchOnly),
      ),
    );

    return const Success(unit);
  }
}
