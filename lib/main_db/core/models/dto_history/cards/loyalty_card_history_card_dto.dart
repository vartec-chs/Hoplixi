import '../../../tables/loyalty_card/loyalty_card_items.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'loyalty_card_history_card_dto.freezed.dart';
part 'loyalty_card_history_card_dto.g.dart';

@freezed
sealed class LoyaltyCardHistoryCardDataDto with _$LoyaltyCardHistoryCardDataDto {
  const factory LoyaltyCardHistoryCardDataDto({
    String? programName,
    LoyaltyBarcodeType? barcodeType,
    String? issuer,
    String? website,
    String? phone,
    String? email,
    DateTime? validFrom,
    DateTime? validTo,
    @Default(false) bool hasCardNumber,
    @Default(false) bool hasBarcodeValue,
    @Default(false) bool hasPassword,
  }) = _LoyaltyCardHistoryCardDataDto;

  factory LoyaltyCardHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$LoyaltyCardHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class LoyaltyCardHistoryCardDto with _$LoyaltyCardHistoryCardDto implements VaultHistoryCardDto {
  const factory LoyaltyCardHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required LoyaltyCardHistoryCardDataDto loyaltycard,
  }) = _LoyaltyCardHistoryCardDto;

  factory LoyaltyCardHistoryCardDto.fromJson(Map<String, dynamic> json) => _$LoyaltyCardHistoryCardDtoFromJson(json);
}