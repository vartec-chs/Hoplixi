import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/loyalty_card/loyalty_card_items.dart';
import '../field_update.dart';
import 'vault_item_base_dto.dart';

part 'loyalty_card_dto.freezed.dart';
part 'loyalty_card_dto.g.dart';

@freezed
sealed class LoyaltyCardDataDto with _$LoyaltyCardDataDto {
  const factory LoyaltyCardDataDto({
    required String programName,

    /// Может быть чувствительным значением.
    String? cardNumber,

    /// Может быть точным пользовательским значением.
    String? barcodeValue,

    /// Секрет карты лояльности.
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

@freezed
sealed class PatchLoyaltyCardDataDto with _$PatchLoyaltyCardDataDto {
  const factory PatchLoyaltyCardDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<String> programName,
    @Default(FieldUpdate.keep()) FieldUpdate<String> cardNumber,
    @Default(FieldUpdate.keep()) FieldUpdate<String> barcodeValue,
    @Default(FieldUpdate.keep()) FieldUpdate<String> password,
    @Default(FieldUpdate.keep()) FieldUpdate<LoyaltyBarcodeType> barcodeType,
    @Default(FieldUpdate.keep()) FieldUpdate<String> barcodeTypeOther,
    @Default(FieldUpdate.keep()) FieldUpdate<String> issuer,
    @Default(FieldUpdate.keep()) FieldUpdate<String> website,
    @Default(FieldUpdate.keep()) FieldUpdate<String> phone,
    @Default(FieldUpdate.keep()) FieldUpdate<String> email,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> validFrom,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> validTo,
  }) = _PatchLoyaltyCardDataDto;
}

@freezed
sealed class PatchLoyaltyCardDto with _$PatchLoyaltyCardDto {
  const factory PatchLoyaltyCardDto({
    required VaultItemPatchDto item,
    required PatchLoyaltyCardDataDto loyaltyCard,
  }) = _PatchLoyaltyCardDto;
}
