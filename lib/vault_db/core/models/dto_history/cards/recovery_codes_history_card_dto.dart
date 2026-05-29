import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'recovery_codes_history_card_dto.freezed.dart';
part 'recovery_codes_history_card_dto.g.dart';

@freezed
sealed class RecoveryCodesHistoryCardDataDto
    with _$RecoveryCodesHistoryCardDataDto {
  const factory RecoveryCodesHistoryCardDataDto({
    DateTime? generatedAt,
    bool? oneTime,
  }) = _RecoveryCodesHistoryCardDataDto;

  factory RecoveryCodesHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class RecoveryCodesHistoryCardDto
    with _$RecoveryCodesHistoryCardDto
    implements VaultHistoryCardDto {
  const factory RecoveryCodesHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required RecoveryCodesHistoryCardDataDto recoveryCodes,
  }) = _RecoveryCodesHistoryCardDto;

  factory RecoveryCodesHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesHistoryCardDtoFromJson(json);
}
