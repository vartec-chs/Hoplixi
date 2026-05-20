import 'package:hoplixi/vault_db/core/models/dto/crypto_wallet_dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

extension CryptoWalletItemsDataMapper on CryptoWalletItemsData {
  CryptoWalletDataDto toCryptoWalletDataDto() {
    return CryptoWalletDataDto(
      walletType: walletType,
      walletTypeOther: walletTypeOther,
      network: network,
      networkOther: networkOther,
      mnemonic: mnemonic,
      privateKey: privateKey,
      derivationPath: derivationPath,
      derivationScheme: derivationScheme,
      derivationSchemeOther: derivationSchemeOther,
      addresses: addresses,
      xpub: xpub,
      xprv: xprv,
      hardwareDevice: hardwareDevice,
      watchOnly: watchOnly,
    );
  }

  CryptoWalletCardDataDto toCryptoWalletCardDataDto() {
    return CryptoWalletCardDataDto(
      walletType: walletType,
      network: network,
      addresses: addresses,
      xpub: xpub,
      hardwareDevice: hardwareDevice,
      watchOnly: watchOnly,
      hasMnemonic: mnemonic?.isNotEmpty ?? false,
      hasPrivateKey: privateKey?.isNotEmpty ?? false,
      hasXprv: xprv?.isNotEmpty ?? false,
    );
  }
}
