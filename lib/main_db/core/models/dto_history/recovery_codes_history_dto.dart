import 'package:freezed_annotation/freezed_annotation.dart';

import '../dto_history/vault_snapshot_base_dto.dart';

part 'recovery_codes_history_dto.freezed.dart';
part 'recovery_codes_history_dto.g.dart';

@freezed
sealed class RecoveryCodesHistoryDataDto with _$RecoveryCodesHistoryDataDto {
  const factory RecoveryCodesHistoryDataDto({
    @Default(0) int codesCount,
    @Default(0) int usedCount,
    DateTime? generatedAt,
    @Default(false) bool oneTime,
  }) = _RecoveryCodesHistoryDataDto;

  factory RecoveryCodesHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesHistoryDataDtoFromJson(json);
}

@freezed
sealed class RecoveryCodeValueHistoryDataDto
    with _$RecoveryCodeValueHistoryDataDto {
  const factory RecoveryCodeValueHistoryDataDto({
    int? id,
    int? originalCodeId,

    /// Nullable из-за secret history policy.
    String? code,
    @Default(false) bool used,
    DateTime? usedAt,
    int? position,
  }) = _RecoveryCodeValueHistoryDataDto;

  factory RecoveryCodeValueHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodeValueHistoryDataDtoFromJson(json);
}

@freezed
sealed class RecoveryCodesHistoryViewDto with _$RecoveryCodesHistoryViewDto {
  const factory RecoveryCodesHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required RecoveryCodesHistoryDataDto recoveryCodes,

    /// Может содержать секреты, nullable из-за secret history policy.
    @Default([]) List<RecoveryCodeValueHistoryDataDto> codes,
  }) = _RecoveryCodesHistoryViewDto;

  factory RecoveryCodesHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesHistoryViewDtoFromJson(json);
}

@freezed
sealed class RecoveryCodesHistoryCardDataDto
    with _$RecoveryCodesHistoryCardDataDto {
  const factory RecoveryCodesHistoryCardDataDto({
    @Default(0) int codesCount,
    @Default(0) int usedCount,
    DateTime? generatedAt,
    @Default(false) bool oneTime,
    required bool hasCodeValues,
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
