import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'identity_history_card_dto.freezed.dart';
part 'identity_history_card_dto.g.dart';

@freezed
sealed class IdentityHistoryCardDataDto with _$IdentityHistoryCardDataDto {
  const factory IdentityHistoryCardDataDto({
    String? firstName,
    String? middleName,
    String? lastName,
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? address,
    DateTime? birthday,
    String? company,
    String? jobTitle,
    String? website,
    String? taxId,
    String? nationalId,
    String? passportNumber,
    String? driverLicenseNumber,
  }) = _IdentityHistoryCardDataDto;

  factory IdentityHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$IdentityHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class IdentityHistoryCardDto
    with _$IdentityHistoryCardDto
    implements VaultHistoryCardDto {
  const factory IdentityHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required IdentityHistoryCardDataDto identity,
  }) = _IdentityHistoryCardDto;

  factory IdentityHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$IdentityHistoryCardDtoFromJson(json);
}
