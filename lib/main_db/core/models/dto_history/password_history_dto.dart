import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault_snapshot_base_dto.dart';

part 'password_history_dto.freezed.dart';
part 'password_history_dto.g.dart';

@freezed
sealed class PasswordHistoryDataDto with _$PasswordHistoryDataDto {
  const factory PasswordHistoryDataDto({
    String? login,
    String? email,
    String? password,
    String? url,
    DateTime? expiresAt,
  }) = _PasswordHistoryDataDto;

  factory PasswordHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$PasswordHistoryDataDtoFromJson(json);
}

@freezed
sealed class PasswordHistoryViewDto with _$PasswordHistoryViewDto {
  const factory PasswordHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required PasswordHistoryDataDto password,
  }) = _PasswordHistoryViewDto;

  factory PasswordHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$PasswordHistoryViewDtoFromJson(json);
}

@freezed
sealed class PasswordHistoryCardDataDto with _$PasswordHistoryCardDataDto {
  const factory PasswordHistoryCardDataDto({
    String? login,
    String? email,
    String? url,
    DateTime? expiresAt,
    required bool hasPassword,
  }) = _PasswordHistoryCardDataDto;

  factory PasswordHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$PasswordHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class PasswordHistoryCardDto with _$PasswordHistoryCardDto {
  const factory PasswordHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required PasswordHistoryCardDataDto password,
  }) = _PasswordHistoryCardDto;

  factory PasswordHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$PasswordHistoryCardDtoFromJson(json);
}
