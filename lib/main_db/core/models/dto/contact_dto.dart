import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault_item_base_dto.dart';

part 'contact_dto.freezed.dart';
part 'contact_dto.g.dart';

@freezed
sealed class ContactDataDto with _$ContactDataDto {
  const factory ContactDataDto({
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
    String? phone,
    String? email,
    String? company,
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
  }) = _CreateContactDto;

  factory CreateContactDto.fromJson(Map<String, dynamic> json) =>
      _$CreateContactDtoFromJson(json);
}

@freezed
sealed class UpdateContactDto with _$UpdateContactDto {
  const factory UpdateContactDto({
    required VaultItemUpdateDto item,
    required ContactDataDto contact,
  }) = _UpdateContactDto;

  factory UpdateContactDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateContactDtoFromJson(json);
}

@freezed
sealed class ContactViewDto with _$ContactViewDto {
  const factory ContactViewDto({
    required VaultItemViewDto item,
    required ContactDataDto contact,
  }) = _ContactViewDto;

  factory ContactViewDto.fromJson(Map<String, dynamic> json) =>
      _$ContactViewDtoFromJson(json);
}

@freezed
sealed class ContactCardDto with _$ContactCardDto {
  const factory ContactCardDto({
    required VaultItemCardDto item,
    required ContactCardDataDto contact,
  }) = _ContactCardDto;

  factory ContactCardDto.fromJson(Map<String, dynamic> json) =>
      _$ContactCardDtoFromJson(json);
}
