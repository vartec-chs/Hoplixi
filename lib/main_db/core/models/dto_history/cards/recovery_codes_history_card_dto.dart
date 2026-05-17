import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'recovery_codes_history_card_dto.freezed.dart';
part 'recovery_codes_history_card_dto.g.dart';

@freezed
sealed class RecoveryCodesHistoryCardDataDto with _$RecoveryCodesHistoryCardDataDto {
  const factory RecoveryCodesHistoryCardDataDto({
    int? codesCount,
    int? usedCount,
    DateTime? generatedAt,
    bool? oneTime,
    @Default(false) bool hasCodeValues,
  }) = _RecoveryCodesHistoryCardDataDto;

  factory RecoveryCodesHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$RecoveryCodesHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class RecoveryCodeValueHistorySecretDto with _$RecoveryCodeValueHistorySecretDto {
  const factory RecoveryCodeValueHistorySecretDto({
    required int id,
    required String code,
    required bool used,
    DateTime? usedAt,
    int? position,
  }) = _RecoveryCodeValueHistorySecretDto;

  factory RecoveryCodeValueHistorySecretDto.fromJson(Map<String, dynamic> json) => _$RecoveryCodeValueHistorySecretDtoFromJson(json);
}

@freezed
sealed class RecoveryCodesHistoryCardDto with _$RecoveryCodesHistoryCardDto implements VaultHistoryCardDto {
  const factory RecoveryCodesHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required RecoveryCodesHistoryCardDataDto recoverycodes,
  }) = _RecoveryCodesHistoryCardDto;

  factory RecoveryCodesHistoryCardDto.fromJson(Map<String, dynamic> json) => _$RecoveryCodesHistoryCardDtoFromJson(json);
}
