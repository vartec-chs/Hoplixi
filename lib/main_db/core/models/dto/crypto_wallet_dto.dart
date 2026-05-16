import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/crypto_wallet/crypto_wallet_items.dart';
import '../field_update.dart';
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
    @Default([]) List<String> tagIds,
  }) = _CreateCryptoWalletDto;

  factory CreateCryptoWalletDto.fromJson(Map<String, dynamic> json) =>
      _$CreateCryptoWalletDtoFromJson(json);
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
sealed class CryptoWalletCardDto with _$CryptoWalletCardDto implements VaultEntityCardDto {
  const factory CryptoWalletCardDto({
    required VaultItemCardDto item,
    required CryptoWalletCardDataDto cryptoWallet,
  }) = _CryptoWalletCardDto;

  factory CryptoWalletCardDto.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletCardDtoFromJson(json);
}

@freezed
sealed class PatchCryptoWalletDataDto with _$PatchCryptoWalletDataDto {
  const factory PatchCryptoWalletDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<CryptoWalletType> walletType,
    @Default(FieldUpdate.keep()) FieldUpdate<String> walletTypeOther,
    @Default(FieldUpdate.keep()) FieldUpdate<CryptoNetwork> network,
    @Default(FieldUpdate.keep()) FieldUpdate<String> networkOther,
    @Default(FieldUpdate.keep()) FieldUpdate<String> mnemonic,
    @Default(FieldUpdate.keep()) FieldUpdate<String> privateKey,
    @Default(FieldUpdate.keep()) FieldUpdate<String> derivationPath,
    @Default(FieldUpdate.keep()) FieldUpdate<CryptoDerivationScheme> derivationScheme,
    @Default(FieldUpdate.keep()) FieldUpdate<String> derivationSchemeOther,
    @Default(FieldUpdate.keep()) FieldUpdate<String> addresses,
    @Default(FieldUpdate.keep()) FieldUpdate<String> xpub,
    @Default(FieldUpdate.keep()) FieldUpdate<String> xprv,
    @Default(FieldUpdate.keep()) FieldUpdate<String> hardwareDevice,
    @Default(FieldUpdate.keep()) FieldUpdate<bool> watchOnly,
  }) = _PatchCryptoWalletDataDto;
}

@freezed
sealed class PatchCryptoWalletDto with _$PatchCryptoWalletDto {
  const factory PatchCryptoWalletDto({
    required VaultItemPatchDto item,
    required PatchCryptoWalletDataDto cryptoWallet,
    @Default(FieldUpdate.keep()) FieldUpdate<List<String>> tags,
  }) = _PatchCryptoWalletDto;
}
