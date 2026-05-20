import '../../../tables/otp/otp_items.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'otp_history_card_dto.freezed.dart';
part 'otp_history_card_dto.g.dart';

@freezed
sealed class OtpHistoryCardDataDto with _$OtpHistoryCardDataDto {
  const factory OtpHistoryCardDataDto({
    OtpType? type,
    String? issuer,
    String? accountName,
    OtpHashAlgorithm? algorithm,
    int? digits,
    int? period,
    int? counter,
    @Default(false) bool hasSecret,
  }) = _OtpHistoryCardDataDto;

  factory OtpHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$OtpHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class OtpHistoryCardDto
    with _$OtpHistoryCardDto
    implements VaultHistoryCardDto {
  const factory OtpHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required OtpHistoryCardDataDto otp,
  }) = _OtpHistoryCardDto;

  factory OtpHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$OtpHistoryCardDtoFromJson(json);
}
