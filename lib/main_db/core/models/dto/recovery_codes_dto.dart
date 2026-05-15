import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault_item_base_dto.dart';

part 'recovery_codes_dto.freezed.dart';
part 'recovery_codes_dto.g.dart';

@freezed
sealed class RecoveryCodesDataDto with _$RecoveryCodesDataDto {
  const factory RecoveryCodesDataDto({
    @Default(0) int codesCount,
    @Default(0) int usedCount,
    DateTime? generatedAt,
    @Default(false) bool oneTime,
  }) = _RecoveryCodesDataDto;

  factory RecoveryCodesDataDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesDataDtoFromJson(json);
}

@freezed
sealed class RecoveryCodeValueDto with _$RecoveryCodeValueDto {
  const factory RecoveryCodeValueDto({
    int? id,
    required String code,
    @Default(false) bool used,
    DateTime? usedAt,
    int? position,
  }) = _RecoveryCodeValueDto;

  factory RecoveryCodeValueDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodeValueDtoFromJson(json);
}

@freezed
sealed class RecoveryCodeValueCardDto with _$RecoveryCodeValueCardDto {
  const factory RecoveryCodeValueCardDto({
    int? id,
    @Default(false) bool used,
    DateTime? usedAt,
    int? position,
    required bool hasCode,
  }) = _RecoveryCodeValueCardDto;

  factory RecoveryCodeValueCardDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodeValueCardDtoFromJson(json);
}

@freezed
sealed class RecoveryCodesCardDataDto with _$RecoveryCodesCardDataDto {
  const factory RecoveryCodesCardDataDto({
    @Default(0) int codesCount,
    @Default(0) int usedCount,
    DateTime? generatedAt,
    @Default(false) bool oneTime,
    required bool hasCodes,
  }) = _RecoveryCodesCardDataDto;

  factory RecoveryCodesCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesCardDataDtoFromJson(json);
}

@freezed
sealed class CreateRecoveryCodesDto with _$CreateRecoveryCodesDto {
  const factory CreateRecoveryCodesDto({
    required VaultItemCreateDto item,

    /// Aggregate fields. codesCount/usedCount могут быть пересчитаны триггерами,
    /// но DTO хранит generatedAt/oneTime.
    required RecoveryCodesDataDto recoveryCodes,

    /// Optional list of codes to insert with the item.
    @Default([]) List<RecoveryCodeValueDto> codes,
  }) = _CreateRecoveryCodesDto;

  factory CreateRecoveryCodesDto.fromJson(Map<String, dynamic> json) =>
      _$CreateRecoveryCodesDtoFromJson(json);
}

@freezed
sealed class UpdateRecoveryCodesDto with _$UpdateRecoveryCodesDto {
  const factory UpdateRecoveryCodesDto({
    required VaultItemUpdateDto item,
    required RecoveryCodesDataDto recoveryCodes,
  }) = _UpdateRecoveryCodesDto;

  factory UpdateRecoveryCodesDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateRecoveryCodesDtoFromJson(json);
}

@freezed
sealed class RecoveryCodesViewDto with _$RecoveryCodesViewDto {
  const factory RecoveryCodesViewDto({
    required VaultItemViewDto item,
    required RecoveryCodesDataDto recoveryCodes,

    /// Full view may contain secrets.
    @Default([]) List<RecoveryCodeValueDto> codes,
  }) = _RecoveryCodesViewDto;

  factory RecoveryCodesViewDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesViewDtoFromJson(json);
}

@freezed
sealed class RecoveryCodesCardDto with _$RecoveryCodesCardDto {
  const factory RecoveryCodesCardDto({
    required VaultItemCardDto item,
    required RecoveryCodesCardDataDto recoveryCodes,
  }) = _RecoveryCodesCardDto;

  factory RecoveryCodesCardDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesCardDtoFromJson(json);
}
