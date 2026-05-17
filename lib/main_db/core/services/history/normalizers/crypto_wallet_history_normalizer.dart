import 'package:hoplixi/main_db/core/repositories/base/crypto_wallet_repository.dart';

import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/crypto_wallet_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class CryptoWalletHistoryNormalizer implements VaultHistoryTypeNormalizer {
  CryptoWalletHistoryNormalizer({
    required this.cryptoWalletHistoryDao,
    required this.cryptoWalletRepository,
  });

  final CryptoWalletHistoryDao cryptoWalletHistoryDao;
  final CryptoWalletRepository cryptoWalletRepository;

  @override
  VaultItemType get type => VaultItemType.cryptoWallet;

  @override
  Future<HistoryPayload?> normalizeHistory({
    required String historyId,
  }) async {
    final rows = await cryptoWalletHistoryDao.getCryptoWalletHistoryByHistoryIds([historyId]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return CryptoWalletHistoryPayload(
      walletType: item.walletType,
      walletTypeOther: item.walletTypeOther,
      network: item.network,
      networkOther: item.networkOther,
      mnemonic: item.mnemonic,
      privateKey: item.privateKey,
      derivationPath: item.derivationPath,
      derivationScheme: item.derivationScheme,
      derivationSchemeOther: item.derivationSchemeOther,
      addresses: item.addresses,
      xpub: item.xpub,
      xprv: item.xprv,
      hardwareDevice: item.hardwareDevice,
      watchOnly: item.watchOnly,
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({
    required String itemId,
  }) async {
    final view = await cryptoWalletRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.cryptoWallet;

    return CryptoWalletHistoryPayload(
      walletType: item.walletType,
      walletTypeOther: item.walletTypeOther,
      network: item.network,
      networkOther: item.networkOther,
      mnemonic: item.mnemonic,
      privateKey: item.privateKey,
      derivationPath: item.derivationPath,
      derivationScheme: item.derivationScheme,
      derivationSchemeOther: item.derivationSchemeOther,
      addresses: item.addresses,
      xpub: item.xpub,
      xprv: item.xprv,
      hardwareDevice: item.hardwareDevice,
      watchOnly: item.watchOnly,
    );
  }
}
