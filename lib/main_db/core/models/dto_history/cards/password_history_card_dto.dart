import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'password_history_card_dto.freezed.dart';
part 'password_history_card_dto.g.dart';

@freezed
sealed class PasswordHistoryCardDataDto with _$PasswordHistoryCardDataDto {
  const factory PasswordHistoryCardDataDto({
    String? login,
    String? email,
    String? url,
    DateTime? expiresAt,
    @Default(false) bool hasPassword,
  }) = _PasswordHistoryCardDataDto;

  factory PasswordHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$PasswordHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class PasswordHistoryCardDto with _$PasswordHistoryCardDto implements VaultHistoryCardDto {
  const factory PasswordHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required PasswordHistoryCardDataDto password,
  }) = _PasswordHistoryCardDto;

  factory PasswordHistoryCardDto.fromJson(Map<String, dynamic> json) => _$PasswordHistoryCardDtoFromJson(json);
}