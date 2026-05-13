import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault_item_base_dto.dart';

part 'identity_dto.freezed.dart';
part 'identity_dto.g.dart';

@freezed
sealed class IdentityDataDto with _$IdentityDataDto {
  const factory IdentityDataDto({
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
  }) = _IdentityDataDto;

  factory IdentityDataDto.fromJson(Map<String, dynamic> json) =>
      _$IdentityDataDtoFromJson(json);
}

@freezed
sealed class IdentityCardDataDto with _$IdentityCardDataDto {
  const factory IdentityCardDataDto({
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? company,
  }) = _IdentityCardDataDto;

  factory IdentityCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$IdentityCardDataDtoFromJson(json);
}

@freezed
sealed class CreateIdentityDto with _$CreateIdentityDto {
  const factory CreateIdentityDto({
    required VaultItemCreateDto item,
    required IdentityDataDto identity,
  }) = _CreateIdentityDto;

  factory CreateIdentityDto.fromJson(Map<String, dynamic> json) =>
      _$CreateIdentityDtoFromJson(json);
}

@freezed
sealed class UpdateIdentityDto with _$UpdateIdentityDto {
  const factory UpdateIdentityDto({
    required VaultItemUpdateDto item,
    required IdentityDataDto identity,
  }) = _UpdateIdentityDto;

  factory UpdateIdentityDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateIdentityDtoFromJson(json);
}

@freezed
sealed class IdentityViewDto with _$IdentityViewDto {
  const factory IdentityViewDto({
    required VaultItemViewDto item,
    required IdentityDataDto identity,
  }) = _IdentityViewDto;

  factory IdentityViewDto.fromJson(Map<String, dynamic> json) =>
      _$IdentityViewDtoFromJson(json);
}

@freezed
sealed class IdentityCardDto with _$IdentityCardDto {
  const factory IdentityCardDto({
    required VaultItemCardDto item,
    required IdentityCardDataDto identity,
  }) = _IdentityCardDto;

  factory IdentityCardDto.fromJson(Map<String, dynamic> json) =>
      _$IdentityCardDtoFromJson(json);
}
