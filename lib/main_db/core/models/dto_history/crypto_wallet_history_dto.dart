import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/crypto_wallet/crypto_wallet_items.dart';
import 'vault_snapshot_base_dto.dart';

part 'crypto_wallet_history_dto.freezed.dart';
part 'crypto_wallet_history_dto.g.dart';

@freezed
sealed class CryptoWalletHistoryDataDto with _$CryptoWalletHistoryDataDto {
  const factory CryptoWalletHistoryDataDto({
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
  }) = _CryptoWalletHistoryDataDto;

  factory CryptoWalletHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletHistoryDataDtoFromJson(json);
}

@freezed
sealed class CryptoWalletHistoryViewDto with _$CryptoWalletHistoryViewDto {
  const factory CryptoWalletHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required CryptoWalletHistoryDataDto cryptoWallet,
  }) = _CryptoWalletHistoryViewDto;

  factory CryptoWalletHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletHistoryViewDtoFromJson(json);
}

@freezed
sealed class CryptoWalletHistoryCardDataDto with _$CryptoWalletHistoryCardDataDto {
  const factory CryptoWalletHistoryCardDataDto({
    CryptoWalletType? walletType,
    String? walletTypeOther,
    CryptoNetwork? network,
    String? networkOther,
    String? derivationPath,
    CryptoDerivationScheme? derivationScheme,
    String? derivationSchemeOther,
    String? addresses,
    String? xpub,
    String? hardwareDevice,
    @Default(false) bool watchOnly,
    required bool hasMnemonic,
    required bool hasPrivateKey,
    required bool hasXprv,
  }) = _CryptoWalletHistoryCardDataDto;

  factory CryptoWalletHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class CryptoWalletHistoryCardDto with _$CryptoWalletHistoryCardDto {
  const factory CryptoWalletHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required CryptoWalletHistoryCardDataDto cryptoWallet,
  }) = _CryptoWalletHistoryCardDto;

  factory CryptoWalletHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletHistoryCardDtoFromJson(json);
}
