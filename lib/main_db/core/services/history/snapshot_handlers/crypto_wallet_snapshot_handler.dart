import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class CryptoWalletSnapshotHandler implements VaultSnapshotTypeHandler {
  CryptoWalletSnapshotHandler({required this.cryptoWalletHistoryDao});

  final CryptoWalletHistoryDao cryptoWalletHistoryDao;

  @override
  VaultItemType get type => VaultItemType.cryptoWallet;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! CryptoWalletViewDto) {
      return Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for CryptoWallet snapshot',
          entity: 'cryptoWallet',
        ),
      );
    }

    final wallet = view.cryptoWallet;

    await cryptoWalletHistoryDao.insertCryptoWalletHistory(
      CryptoWalletHistoryCompanion.insert(
        historyId: historyId,
        walletType: Value(wallet.walletType),
        walletTypeOther: Value(wallet.walletTypeOther),
        network: Value(wallet.network),
        networkOther: Value(wallet.networkOther),
        mnemonic: Value(includeSecrets ? wallet.mnemonic : null),
        privateKey: Value(includeSecrets ? wallet.privateKey : null),
        derivationPath: Value(wallet.derivationPath),
        derivationScheme: Value(wallet.derivationScheme),
        derivationSchemeOther: Value(wallet.derivationSchemeOther),
        addresses: Value(wallet.addresses),
        xpub: Value(wallet.xpub),
        xprv: Value(includeSecrets ? wallet.xprv : null),
        hardwareDevice: Value(wallet.hardwareDevice),
        watchOnly: Value(wallet.watchOnly),
      ),
    );

    return const Success(unit);
  }
}
