import 'package:freezed_annotation/freezed_annotation.dart';

import '../field_update.dart';
import 'vault_item_base_dto.dart';

part 'contact_dto.freezed.dart';
part 'contact_dto.g.dart';

@freezed
sealed class ContactDataDto with _$ContactDataDto {
  const factory ContactDataDto({
    required String firstName,
    String? middleName,
    String? lastName,
    String? phone,
    String? email,
    String? company,
    String? jobTitle,
    String? address,
    String? website,
    DateTime? birthday,
    @Default(false) bool isEmergencyContact,
  }) = _ContactDataDto;

  factory ContactDataDto.fromJson(Map<String, dynamic> json) =>
      _$ContactDataDtoFromJson(json);
}

@freezed
sealed class ContactCardDataDto with _$ContactCardDataDto {
  const factory ContactCardDataDto({
    required String firstName,
    String? middleName,
    String? lastName,
    String? company,
    String? phone,
    String? email,
    @Default(false) bool isEmergencyContact,
  }) = _ContactCardDataDto;

  factory ContactCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$ContactCardDataDtoFromJson(json);
}

@freezed
sealed class CreateContactDto with _$CreateContactDto {
  const factory CreateContactDto({
    required VaultItemCreateDto item,
    required ContactDataDto contact,
    @Default([]) List<String> tagIds,
  }) = _CreateContactDto;

  factory CreateContactDto.fromJson(Map<String, dynamic> json) =>
      _$CreateContactDtoFromJson(json);
}

@freezed
sealed class ContactViewDto with _$ContactViewDto implements VaultEntityViewDto {
  const factory ContactViewDto({
    required VaultItemViewDto item,
    required ContactDataDto contact,
  }) = _ContactViewDto;

  factory ContactViewDto.fromJson(Map<String, dynamic> json) =>
      _$ContactViewDtoFromJson(json);
}

@freezed
sealed class ContactCardDto with _$ContactCardDto implements VaultEntityCardDto {
  const factory ContactCardDto({
    required VaultItemCardDto item,
    required ContactCardDataDto contact,
  }) = _ContactCardDto;

  factory ContactCardDto.fromJson(Map<String, dynamic> json) =>
      _$ContactCardDtoFromJson(json);
}

@freezed
sealed class PatchContactDataDto with _$PatchContactDataDto {
  const factory PatchContactDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<String> firstName,
    @Default(FieldUpdate.keep()) FieldUpdate<String> middleName,
    @Default(FieldUpdate.keep()) FieldUpdate<String> lastName,
    @Default(FieldUpdate.keep()) FieldUpdate<String> phone,
    @Default(FieldUpdate.keep()) FieldUpdate<String> email,
    @Default(FieldUpdate.keep()) FieldUpdate<String> company,
    @Default(FieldUpdate.keep()) FieldUpdate<String> jobTitle,
    @Default(FieldUpdate.keep()) FieldUpdate<String> address,
    @Default(FieldUpdate.keep()) FieldUpdate<String> website,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> birthday,
    @Default(FieldUpdate.keep()) FieldUpdate<bool> isEmergencyContact,
  }) = _PatchContactDataDto;
}

@freezed
sealed class PatchContactDto with _$PatchContactDto {
  const factory PatchContactDto({
    required VaultItemPatchDto item,
    required PatchContactDataDto contact,
    @Default(FieldUpdate.keep()) FieldUpdate<List<String>> tags,
  }) = _PatchContactDto;
}


