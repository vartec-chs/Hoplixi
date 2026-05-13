import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/crypto_wallet/crypto_wallet_items.dart';
import 'vault_item_base_dto.dart';

part 'crypto_wallet_dto.freezed.dart';
part 'crypto_wallet_dto.g.dart';

@freezed
sealed class CryptoWalletDataDto with _$CryptoWalletDataDto {
  const factory CryptoWalletDataDto({
    CryptoWalletType? walletType,
    String? walletTypeOther,
    CryptoNetwork? network,
    String? networkOther,
    String? mnemonic,
    String? privateKey,
    String? derivationPath,
    CryptoDerivationScheme? derivationScheme,
    String? derivationSchemeOther,
    String? addresses,
    String? xpub,
    String? xprv,
    String? hardwareDevice,
    @Default(false) bool watchOnly,
  }) = _CryptoWalletDataDto;

  factory CryptoWalletDataDto.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletDataDtoFromJson(json);
}

@freezed
sealed class CryptoWalletCardDataDto with _$CryptoWalletCardDataDto {
  const factory CryptoWalletCardDataDto({
    CryptoWalletType? walletType,
    CryptoNetwork? network,
    String? addresses,
    String? xpub,
    String? hardwareDevice,
    @Default(false) bool watchOnly,
    @Default(false) bool hasMnemonic,
    @Default(false) bool hasPrivateKey,
    @Default(false) bool hasXprv,
  }) = _CryptoWalletCardDataDto;

  factory CryptoWalletCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletCardDataDtoFromJson(json);
}

@freezed
sealed class CreateCryptoWalletDto with _$CreateCryptoWalletDto {
  const factory CreateCryptoWalletDto({
    required VaultItemCreateDto item,
    required CryptoWalletDataDto cryptoWallet,
  }) = _CreateCryptoWalletDto;

  factory CreateCryptoWalletDto.fromJson(Map<String, dynamic> json) =>
      _$CreateCryptoWalletDtoFromJson(json);
}

@freezed
sealed class UpdateCryptoWalletDto with _$UpdateCryptoWalletDto {
  const factory UpdateCryptoWalletDto({
    required VaultItemUpdateDto item,
    required CryptoWalletDataDto cryptoWallet,
  }) = _UpdateCryptoWalletDto;

  factory UpdateCryptoWalletDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateCryptoWalletDtoFromJson(json);
}

@freezed
sealed class CryptoWalletViewDto with _$CryptoWalletViewDto {
  const factory CryptoWalletViewDto({
    required VaultItemViewDto item,
    required CryptoWalletDataDto cryptoWallet,
  }) = _CryptoWalletViewDto;

  factory CryptoWalletViewDto.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletViewDtoFromJson(json);
}

@freezed
sealed class CryptoWalletCardDto with _$CryptoWalletCardDto {
  const factory CryptoWalletCardDto({
    required VaultItemCardDto item,
    required CryptoWalletCardDataDto cryptoWallet,
  }) = _CryptoWalletCardDto;

  factory CryptoWalletCardDto.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletCardDtoFromJson(json);
}
