import 'package:hoplixi/vault_db/core/repositories/base/crypto_wallet_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
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
  AsyncDbResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return tryCatchAsync(
      () async {
        final rows = await cryptoWalletHistoryDao
            .getCryptoWalletHistoryByHistoryIds([historyId]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          CryptoWalletHistoryPayload(
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
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории криптокошелька',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  @override
  AsyncDbResult<Optional<HistoryPayload>> normalizeCurrent({
    required String itemId,
  }) {
    return tryCatchAsync(
      () async {
        final viewOpt = (await cryptoWalletRepository.getViewById(
          itemId,
        )).getOrThrow();
        return viewOpt.fold((view) {
          final item = view.cryptoWallet;
          return Some(
            CryptoWalletHistoryPayload(
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
            ),
          );
        }, () => const None());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message:
                  'Ошибка при нормализации текущего состояния криптокошелька',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
