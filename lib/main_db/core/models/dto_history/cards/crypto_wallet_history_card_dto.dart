import '../../../tables/crypto_wallet/crypto_wallet_items.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'crypto_wallet_history_card_dto.freezed.dart';
part 'crypto_wallet_history_card_dto.g.dart';

@freezed
sealed class CryptoWalletHistoryCardDataDto with _$CryptoWalletHistoryCardDataDto {
  const factory CryptoWalletHistoryCardDataDto({
    CryptoWalletType? walletType,
    CryptoNetwork? network,
    String? derivationPath,
    CryptoDerivationScheme? derivationScheme,
    String? addresses,
    String? xpub,
    String? hardwareDevice,
    bool? watchOnly,
    @Default(false) bool hasMnemonic,
    @Default(false) bool hasPrivateKey,
    @Default(false) bool hasXprv,
  }) = _CryptoWalletHistoryCardDataDto;

  factory CryptoWalletHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$CryptoWalletHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class CryptoWalletHistoryCardDto with _$CryptoWalletHistoryCardDto implements VaultHistoryCardDto {
  const factory CryptoWalletHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required CryptoWalletHistoryCardDataDto cryptowallet,
  }) = _CryptoWalletHistoryCardDto;

  factory CryptoWalletHistoryCardDto.fromJson(Map<String, dynamic> json) => _$CryptoWalletHistoryCardDtoFromJson(json);
}