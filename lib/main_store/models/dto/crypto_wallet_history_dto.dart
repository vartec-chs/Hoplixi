import 'package:freezed_annotation/freezed_annotation.dart';

part 'crypto_wallet_history_dto.freezed.dart';
part 'crypto_wallet_history_dto.g.dart';

@freezed
sealed class CryptoWalletHistoryCardDto with _$CryptoWalletHistoryCardDto {
  const factory CryptoWalletHistoryCardDto({
    required String id,
    required String originalCryptoWalletId,
    required String action,
    required String name,
    required String walletType,
    String? network,
    required bool watchOnly,
    DateTime? lastBalanceCheckedAt,
    required DateTime actionAt,
  }) = _CryptoWalletHistoryCardDto;

  factory CryptoWalletHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletHistoryCardDtoFromJson(json);
}
