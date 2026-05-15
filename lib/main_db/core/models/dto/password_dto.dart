import 'package:freezed_annotation/freezed_annotation.dart';

import '../field_update.dart';
import 'vault_item_base_dto.dart';

part 'password_dto.freezed.dart';
part 'password_dto.g.dart';

@freezed
sealed class PasswordDataDto with _$PasswordDataDto {
  const factory PasswordDataDto({
    String? login,
    String? email,
    required String password,
    String? url,
    DateTime? expiresAt,
  }) = _PasswordDataDto;

  factory PasswordDataDto.fromJson(Map<String, dynamic> json) =>
      _$PasswordDataDtoFromJson(json);
}

@freezed
sealed class PasswordCardDataDto with _$PasswordCardDataDto {
  const factory PasswordCardDataDto({
    String? login,
    String? email,
    String? url,
    DateTime? expiresAt,
    @Default(true) bool hasPassword,
  }) = _PasswordCardDataDto;

  factory PasswordCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$PasswordCardDataDtoFromJson(json);
}

@freezed
sealed class CreatePasswordDto with _$CreatePasswordDto {
  const factory CreatePasswordDto({
    required VaultItemCreateDto item,
    required PasswordDataDto password,
  }) = _CreatePasswordDto;

  factory CreatePasswordDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePasswordDtoFromJson(json);
}

@freezed
sealed class UpdatePasswordDto with _$UpdatePasswordDto {
  const factory UpdatePasswordDto({
    required VaultItemUpdateDto item,
    required PasswordDataDto password,
  }) = _UpdatePasswordDto;

  factory UpdatePasswordDto.fromJson(Map<String, dynamic> json) =>
      _$UpdatePasswordDtoFromJson(json);
}

@freezed
sealed class PasswordViewDto with _$PasswordViewDto {
  const factory PasswordViewDto({
    required VaultItemViewDto item,
    required PasswordDataDto password,
  }) = _PasswordViewDto;

  factory PasswordViewDto.fromJson(Map<String, dynamic> json) =>
      _$PasswordViewDtoFromJson(json);
}

@freezed
sealed class PasswordCardDto with _$PasswordCardDto {
  const factory PasswordCardDto({
    required VaultItemCardDto item,
    required PasswordCardDataDto password,
  }) = _PasswordCardDto;

  factory PasswordCardDto.fromJson(Map<String, dynamic> json) =>
      _$PasswordCardDtoFromJson(json);
}

@freezed
sealed class PatchPasswordDataDto with _$PatchPasswordDataDto {
  const factory PatchPasswordDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<String> login,
    @Default(FieldUpdate.keep()) FieldUpdate<String> email,
    @Default(FieldUpdate.keep()) FieldUpdate<String> password,
    @Default(FieldUpdate.keep()) FieldUpdate<String> url,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> expiresAt,
  }) = _PatchPasswordDataDto;
}

@freezed
sealed class PatchPasswordDto with _$PatchPasswordDto {
  const factory PatchPasswordDto({
    required VaultItemPatchDto item,
    required PatchPasswordDataDto password,
  }) = _PatchPasswordDto;
}
