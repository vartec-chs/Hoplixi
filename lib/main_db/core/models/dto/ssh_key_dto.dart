import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/ssh_key/ssh_key_items.dart';
import '../field_update.dart';
import 'vault_item_base_dto.dart';

part 'ssh_key_dto.freezed.dart';
part 'ssh_key_dto.g.dart';

@freezed
sealed class SshKeyDataDto with _$SshKeyDataDto {
  const factory SshKeyDataDto({
    String? publicKey,
    String? privateKey,
    SshKeyType? keyType,
    String? keyTypeOther,
    int? keySize,
  }) = _SshKeyDataDto;

  factory SshKeyDataDto.fromJson(Map<String, dynamic> json) =>
      _$SshKeyDataDtoFromJson(json);
}

@freezed
sealed class SshKeyCardDataDto with _$SshKeyCardDataDto {
  const factory SshKeyCardDataDto({
    String? publicKey,
    SshKeyType? keyType,
    int? keySize,
    @Default(false) bool hasPrivateKey,
  }) = _SshKeyCardDataDto;

  factory SshKeyCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$SshKeyCardDataDtoFromJson(json);
}

@freezed
sealed class CreateSshKeyDto with _$CreateSshKeyDto {
  const factory CreateSshKeyDto({
    required VaultItemCreateDto item,
    required SshKeyDataDto sshKey,
    @Default([]) List<String> tagIds,
  }) = _CreateSshKeyDto;

  factory CreateSshKeyDto.fromJson(Map<String, dynamic> json) =>
      _$CreateSshKeyDtoFromJson(json);
}

@freezed
sealed class SshKeyViewDto with _$SshKeyViewDto implements VaultEntityViewDto {
  const factory SshKeyViewDto({
    required VaultItemViewDto item,
    required SshKeyDataDto sshKey,
  }) = _SshKeyViewDto;

  factory SshKeyViewDto.fromJson(Map<String, dynamic> json) =>
      _$SshKeyViewDtoFromJson(json);
}

@freezed
sealed class SshKeyCardDto with _$SshKeyCardDto implements VaultEntityCardDto {
  const factory SshKeyCardDto({
    required VaultItemCardDto item,
    required SshKeyCardDataDto sshKey,
  }) = _SshKeyCardDto;

  factory SshKeyCardDto.fromJson(Map<String, dynamic> json) =>
      _$SshKeyCardDtoFromJson(json);
}

@freezed
sealed class PatchSshKeyDataDto with _$PatchSshKeyDataDto {
  const factory PatchSshKeyDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<String> publicKey,
    @Default(FieldUpdate.keep()) FieldUpdate<String> privateKey,
    @Default(FieldUpdate.keep()) FieldUpdate<SshKeyType> keyType,
    @Default(FieldUpdate.keep()) FieldUpdate<String> keyTypeOther,
    @Default(FieldUpdate.keep()) FieldUpdate<int> keySize,
  }) = _PatchSshKeyDataDto;
}

@freezed
sealed class PatchSshKeyDto with _$PatchSshKeyDto {
  const factory PatchSshKeyDto({
    required VaultItemPatchDto item,
    required PatchSshKeyDataDto sshKey,
    @Default(FieldUpdate.keep()) FieldUpdate<List<String>> tags,
  }) = _PatchSshKeyDto;
}


