import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/bank_card/bank_card_items.dart';
import 'vault_item_base_dto.dart';

part 'bank_card_dto.freezed.dart';
part 'bank_card_dto.g.dart';

@freezed
sealed class BankCardDataDto with _$BankCardDataDto {
  const factory BankCardDataDto({
    String? cardholderName,
    required String cardNumber,
    CardType? cardType,
    String? cardTypeOther,
    CardNetwork? cardNetwork,
    String? cardNetworkOther,
    String? expiryMonth,
    String? expiryYear,
    String? cvv,
    String? bankName,
    String? accountNumber,
    String? routingNumber,
  }) = _BankCardDataDto;

  factory BankCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardDataDtoFromJson(json);
}

@freezed
sealed class BankCardCardDataDto with _$BankCardCardDataDto {
  const factory BankCardCardDataDto({
    String? cardholderName,
    CardType? cardType,
    CardNetwork? cardNetwork,
    String? expiryMonth,
    String? expiryYear,
    String? bankName,
    @Default(false) bool hasCvv,
    @Default(true) bool hasCardNumber,
  }) = _BankCardCardDataDto;

  factory BankCardCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardCardDataDtoFromJson(json);
}

@freezed
sealed class CreateBankCardDto with _$CreateBankCardDto {
  const factory CreateBankCardDto({
    required VaultItemCreateDto item,
    required BankCardDataDto bankCard,
  }) = _CreateBankCardDto;

  factory CreateBankCardDto.fromJson(Map<String, dynamic> json) =>
      _$CreateBankCardDtoFromJson(json);
}

@freezed
sealed class UpdateBankCardDto with _$UpdateBankCardDto {
  const factory UpdateBankCardDto({
    required VaultItemUpdateDto item,
    required BankCardDataDto bankCard,
  }) = _UpdateBankCardDto;

  factory UpdateBankCardDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateBankCardDtoFromJson(json);
}

@freezed
sealed class BankCardViewDto with _$BankCardViewDto {
  const factory BankCardViewDto({
    required VaultItemViewDto item,
    required BankCardDataDto bankCard,
  }) = _BankCardViewDto;

  factory BankCardViewDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardViewDtoFromJson(json);
}

@freezed
sealed class BankCardCardDto with _$BankCardCardDto {
  const factory BankCardCardDto({
    required VaultItemCardDto item,
    required BankCardCardDataDto bankCard,
  }) = _BankCardCardDto;

  factory BankCardCardDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardCardDtoFromJson(json);
}
