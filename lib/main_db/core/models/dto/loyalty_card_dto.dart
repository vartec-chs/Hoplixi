import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/loyalty_card/loyalty_card_items.dart';
import 'vault_item_base_dto.dart';

part 'loyalty_card_dto.freezed.dart';
part 'loyalty_card_dto.g.dart';

@freezed
sealed class LoyaltyCardDataDto with _$LoyaltyCardDataDto {
  const factory LoyaltyCardDataDto({
    required String programName,
    String? cardNumber,
    String? barcodeValue,
    String? password,
    LoyaltyBarcodeType? barcodeType,
    String? barcodeTypeOther,
    String? issuer,
    String? website,
    String? phone,
    String? email,
    DateTime? validFrom,
    DateTime? validTo,
  }) = _LoyaltyCardDataDto;

  factory LoyaltyCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardDataDtoFromJson(json);
}

@freezed
sealed class LoyaltyCardCardDataDto with _$LoyaltyCardCardDataDto {
  const factory LoyaltyCardCardDataDto({
    required String programName,
    String? cardNumber,
    String? barcodeValue,
    LoyaltyBarcodeType? barcodeType,
    String? issuer,
    DateTime? validTo,
    @Default(false) bool hasPassword,
  }) = _LoyaltyCardCardDataDto;

  factory LoyaltyCardCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardCardDataDtoFromJson(json);
}

@freezed
sealed class CreateLoyaltyCardDto with _$CreateLoyaltyCardDto {
  const factory CreateLoyaltyCardDto({
    required VaultItemCreateDto item,
    required LoyaltyCardDataDto loyaltyCard,
  }) = _CreateLoyaltyCardDto;

  factory CreateLoyaltyCardDto.fromJson(Map<String, dynamic> json) =>
      _$CreateLoyaltyCardDtoFromJson(json);
}

@freezed
sealed class UpdateLoyaltyCardDto with _$UpdateLoyaltyCardDto {
  const factory UpdateLoyaltyCardDto({
    required VaultItemUpdateDto item,
    required LoyaltyCardDataDto loyaltyCard,
  }) = _UpdateLoyaltyCardDto;

  factory UpdateLoyaltyCardDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateLoyaltyCardDtoFromJson(json);
}

@freezed
sealed class LoyaltyCardViewDto with _$LoyaltyCardViewDto {
  const factory LoyaltyCardViewDto({
    required VaultItemViewDto item,
    required LoyaltyCardDataDto loyaltyCard,
  }) = _LoyaltyCardViewDto;

  factory LoyaltyCardViewDto.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardViewDtoFromJson(json);
}

@freezed
sealed class LoyaltyCardCardDto with _$LoyaltyCardCardDto {
  const factory LoyaltyCardCardDto({
    required VaultItemCardDto item,
    required LoyaltyCardCardDataDto loyaltyCard,
  }) = _LoyaltyCardCardDto;

  factory LoyaltyCardCardDto.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardCardDtoFromJson(json);
}
