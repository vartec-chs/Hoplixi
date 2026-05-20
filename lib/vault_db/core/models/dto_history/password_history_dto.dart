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
