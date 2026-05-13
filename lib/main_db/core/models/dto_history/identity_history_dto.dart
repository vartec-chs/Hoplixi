import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault_snapshot_base_dto.dart';

part 'identity_history_dto.freezed.dart';
part 'identity_history_dto.g.dart';

@freezed
sealed class IdentityHistoryDataDto with _$IdentityHistoryDataDto {
  const factory IdentityHistoryDataDto({
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
  }) = _IdentityHistoryDataDto;

  factory IdentityHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$IdentityHistoryDataDtoFromJson(json);
}

@freezed
sealed class IdentityHistoryViewDto with _$IdentityHistoryViewDto {
  const factory IdentityHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required IdentityHistoryDataDto identity,
  }) = _IdentityHistoryViewDto;

  factory IdentityHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$IdentityHistoryViewDtoFromJson(json);
}

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
sealed class IdentityHistoryCardDto with _$IdentityHistoryCardDto {
  const factory IdentityHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required IdentityHistoryCardDataDto identity,
  }) = _IdentityHistoryCardDto;

  factory IdentityHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$IdentityHistoryCardDtoFromJson(json);
}
