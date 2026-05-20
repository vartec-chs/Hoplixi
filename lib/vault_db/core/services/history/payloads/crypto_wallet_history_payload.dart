import '../../../tables/crypto_wallet/crypto_wallet_items.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class CryptoWalletHistoryPayload extends HistoryPayload {
  const CryptoWalletHistoryPayload({
    this.walletType,
    this.walletTypeOther,
    this.network,
    this.networkOther,
    this.mnemonic,
    this.privateKey,
    this.derivationPath,
    this.derivationScheme,
    this.derivationSchemeOther,
    this.addresses,
    this.xpub,
    this.xprv,
    this.hardwareDevice,
    required this.watchOnly,
  });

  final CryptoWalletType? walletType;
  final String? walletTypeOther;
  final CryptoNetwork? network;
  final String? networkOther;
  final String? mnemonic;
  final String? privateKey;
  final String? derivationPath;
  final CryptoDerivationScheme? derivationScheme;
  final String? derivationSchemeOther;
  final String? addresses;
  final String? xpub;
  final String? xprv;
  final String? hardwareDevice;
  final bool watchOnly;

  @override
  VaultItemType get type => VaultItemType.cryptoWallet;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.walletType',
        label: 'Wallet type',
        value: walletType?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.walletTypeOther',
        label: 'Wallet type other',
        value: walletTypeOther,
      ),
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.network',
        label: 'Network',
        value: network?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.networkOther',
        label: 'Network other',
        value: networkOther,
      ),
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.mnemonic',
        label: 'Mnemonic',
        value: mnemonic,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.privateKey',
        label: 'Private key',
        value: privateKey,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.derivationPath',
        label: 'Derivation path',
        value: derivationPath,
      ),
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.derivationScheme',
        label: 'Derivation scheme',
        value: derivationScheme?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.derivationSchemeOther',
        label: 'Derivation scheme other',
        value: derivationSchemeOther,
      ),
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.addresses',
        label: 'Addresses',
        value: addresses,
      ),
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.xpub',
        label: 'xPub',
        value: xpub,
      ),
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.xprv',
        label: 'xPrv',
        value: xprv,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'cryptoWallet.hardwareDevice',
        label: 'Hardware device',
        value: hardwareDevice,
      ),
      HistoryFieldSnapshot<bool>(
        key: 'cryptoWallet.watchOnly',
        label: 'Watch only',
        value: watchOnly,
      ),
    ];
  }
}
