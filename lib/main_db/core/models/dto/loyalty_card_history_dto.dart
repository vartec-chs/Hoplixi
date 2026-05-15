import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/loyalty_card/loyalty_card_items.dart';
import '../dto_history/vault_snapshot_base_dto.dart';

part 'loyalty_card_history_dto.freezed.dart';
part 'loyalty_card_history_dto.g.dart';

@freezed
sealed class LoyaltyCardHistoryDataDto with _$LoyaltyCardHistoryDataDto {
  const factory LoyaltyCardHistoryDataDto({
    required String programName,

    /// Nullable из-за secret history policy.
    String? cardNumber,

    /// Nullable из-за secret history policy.
    String? barcodeValue,

    /// Nullable из-за secret history policy.
    String? password,

    LoyaltyBarcodeType? barcodeType,
    String? barcodeTypeOther,

    String? issuer,
    String? website,
    String? phone,
    String? email,

    DateTime? validFrom,
    DateTime? validTo,
  }) = _LoyaltyCardHistoryDataDto;

  factory LoyaltyCardHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardHistoryDataDtoFromJson(json);
}

@freezed
sealed class LoyaltyCardHistoryViewDto with _$LoyaltyCardHistoryViewDto {
  const factory LoyaltyCardHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required LoyaltyCardHistoryDataDto loyaltyCard,
  }) = _LoyaltyCardHistoryViewDto;

  factory LoyaltyCardHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardHistoryViewDtoFromJson(json);
}

@freezed
sealed class LoyaltyCardHistoryCardDataDto with _$LoyaltyCardHistoryCardDataDto {
  const factory LoyaltyCardHistoryCardDataDto({
    required String programName,

    LoyaltyBarcodeType? barcodeType,
    String? barcodeTypeOther,

    String? issuer,
    String? website,
    String? phone,
    String? email,

    DateTime? validFrom,
    DateTime? validTo,

    required bool hasCardNumber,
    required bool hasBarcodeValue,
    required bool hasPassword,
  }) = _LoyaltyCardHistoryCardDataDto;

  factory LoyaltyCardHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class LoyaltyCardHistoryCardDto with _$LoyaltyCardHistoryCardDto {
  const factory LoyaltyCardHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required LoyaltyCardHistoryCardDataDto loyaltyCard,
  }) = _LoyaltyCardHistoryCardDto;

  factory LoyaltyCardHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardHistoryCardDtoFromJson(json);
}
