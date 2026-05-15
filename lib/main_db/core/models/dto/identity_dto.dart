import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault_item_base_dto.dart';
import '../field_update.dart';

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

@freezed
sealed class PatchIdentityDataDto with _$PatchIdentityDataDto {
  const factory PatchIdentityDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<String> firstName,
    @Default(FieldUpdate.keep()) FieldUpdate<String> middleName,
    @Default(FieldUpdate.keep()) FieldUpdate<String> lastName,
    @Default(FieldUpdate.keep()) FieldUpdate<String> displayName,
    @Default(FieldUpdate.keep()) FieldUpdate<String> username,
    @Default(FieldUpdate.keep()) FieldUpdate<String> email,
    @Default(FieldUpdate.keep()) FieldUpdate<String> phone,
    @Default(FieldUpdate.keep()) FieldUpdate<String> address,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> birthday,
    @Default(FieldUpdate.keep()) FieldUpdate<String> company,
    @Default(FieldUpdate.keep()) FieldUpdate<String> jobTitle,
    @Default(FieldUpdate.keep()) FieldUpdate<String> website,
    @Default(FieldUpdate.keep()) FieldUpdate<String> taxId,
    @Default(FieldUpdate.keep()) FieldUpdate<String> nationalId,
    @Default(FieldUpdate.keep()) FieldUpdate<String> passportNumber,
    @Default(FieldUpdate.keep()) FieldUpdate<String> driverLicenseNumber,
  }) = _PatchIdentityDataDto;
}

@freezed
sealed class PatchIdentityDto with _$PatchIdentityDto {
  const factory PatchIdentityDto({
    required VaultItemPatchDto item,
    required PatchIdentityDataDto identity,
    @Default(FieldUpdate.keep()) FieldUpdate<List<String>> tags,
  }) = _PatchIdentityDto;
}
