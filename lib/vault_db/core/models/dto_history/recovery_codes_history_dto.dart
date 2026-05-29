import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault_snapshot_base_dto.dart';

part 'recovery_codes_history_dto.freezed.dart';
part 'recovery_codes_history_dto.g.dart';

@freezed
sealed class RecoveryCodesHistoryDataDto with _$RecoveryCodesHistoryDataDto {
  const factory RecoveryCodesHistoryDataDto({
    DateTime? generatedAt,
    @Default(false) bool oneTime,
  }) = _RecoveryCodesHistoryDataDto;

  factory RecoveryCodesHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesHistoryDataDtoFromJson(json);
}
@freezed
sealed class RecoveryCodesHistoryViewDto with _$RecoveryCodesHistoryViewDto {
  const factory RecoveryCodesHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required RecoveryCodesHistoryDataDto recoveryCodes,
  }) = _RecoveryCodesHistoryViewDto;

  factory RecoveryCodesHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesHistoryViewDtoFromJson(json);
}

@freezed
sealed class RecoveryCodesHistoryCardDataDto
    with _$RecoveryCodesHistoryCardDataDto {
  const factory RecoveryCodesHistoryCardDataDto({
    DateTime? generatedAt,
    @Default(false) bool oneTime,
  }) = _RecoveryCodesHistoryCardDataDto;

  factory RecoveryCodesHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class RecoveryCodesHistoryCardDto with _$RecoveryCodesHistoryCardDto {
  const factory RecoveryCodesHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required RecoveryCodesHistoryCardDataDto recoveryCodes,
  }) = _RecoveryCodesHistoryCardDto;

  factory RecoveryCodesHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesHistoryCardDtoFromJson(json);
}
