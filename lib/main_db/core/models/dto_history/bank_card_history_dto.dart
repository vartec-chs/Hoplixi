import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/bank_card/bank_card_items.dart';
import 'vault_snapshot_base_dto.dart';

part 'bank_card_history_dto.freezed.dart';
part 'bank_card_history_dto.g.dart';

@freezed
sealed class BankCardHistoryDataDto with _$BankCardHistoryDataDto {
  const factory BankCardHistoryDataDto({
    String? cardholderName,
    String? cardNumber,
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
  }) = _BankCardHistoryDataDto;

  factory BankCardHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardHistoryDataDtoFromJson(json);
}

@freezed
sealed class BankCardHistoryViewDto with _$BankCardHistoryViewDto {
  const factory BankCardHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required BankCardHistoryDataDto bankCard,
  }) = _BankCardHistoryViewDto;

  factory BankCardHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardHistoryViewDtoFromJson(json);
}

@freezed
sealed class BankCardHistoryCardDataDto with _$BankCardHistoryCardDataDto {
  const factory BankCardHistoryCardDataDto({
    String? cardholderName,
    CardType? cardType,
    String? cardTypeOther,
    CardNetwork? cardNetwork,
    String? cardNetworkOther,
    String? expiryMonth,
    String? expiryYear,
    String? bankName,
    String? accountNumber,
    String? routingNumber,
    required bool hasCardNumber,
    required bool hasCvv,
  }) = _BankCardHistoryCardDataDto;

  factory BankCardHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class BankCardHistoryCardDto with _$BankCardHistoryCardDto {
  const factory BankCardHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required BankCardHistoryCardDataDto bankCard,
  }) = _BankCardHistoryCardDto;

  factory BankCardHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardHistoryCardDtoFromJson(json);
}
