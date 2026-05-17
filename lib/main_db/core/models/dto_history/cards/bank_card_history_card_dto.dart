import '../../../tables/bank_card/bank_card_items.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'bank_card_history_card_dto.freezed.dart';
part 'bank_card_history_card_dto.g.dart';

@freezed
sealed class BankCardHistoryCardDataDto with _$BankCardHistoryCardDataDto {
  const factory BankCardHistoryCardDataDto({
    String? cardholderName,
    CardType? cardType,
    CardNetwork? cardNetwork,
    String? expiryMonth,
    String? expiryYear,
    String? bankName,
    @Default(false) bool hasCardNumber,
    @Default(false) bool hasCvv,
    @Default(false) bool hasAccountNumber,
    @Default(false) bool hasRoutingNumber,
  }) = _BankCardHistoryCardDataDto;

  factory BankCardHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class BankCardHistoryCardDto
    with _$BankCardHistoryCardDto
    implements VaultHistoryCardDto {
  const factory BankCardHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required BankCardHistoryCardDataDto bankcard,
  }) = _BankCardHistoryCardDto;

  factory BankCardHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardHistoryCardDtoFromJson(json);
}
