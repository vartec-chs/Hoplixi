import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/ssh_key/ssh_key_items.dart';
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
  }) = _CreateSshKeyDto;

  factory CreateSshKeyDto.fromJson(Map<String, dynamic> json) =>
      _$CreateSshKeyDtoFromJson(json);
}

@freezed
sealed class UpdateSshKeyDto with _$UpdateSshKeyDto {
  const factory UpdateSshKeyDto({
    required VaultItemUpdateDto item,
    required SshKeyDataDto sshKey,
  }) = _UpdateSshKeyDto;

  factory UpdateSshKeyDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateSshKeyDtoFromJson(json);
}

@freezed
sealed class SshKeyViewDto with _$SshKeyViewDto {
  const factory SshKeyViewDto({
    required VaultItemViewDto item,
    required SshKeyDataDto sshKey,
  }) = _SshKeyViewDto;

  factory SshKeyViewDto.fromJson(Map<String, dynamic> json) =>
      _$SshKeyViewDtoFromJson(json);
}

@freezed
sealed class SshKeyCardDto with _$SshKeyCardDto {
  const factory SshKeyCardDto({
    required VaultItemCardDto item,
    required SshKeyCardDataDto sshKey,
  }) = _SshKeyCardDto;

  factory SshKeyCardDto.fromJson(Map<String, dynamic> json) =>
      _$SshKeyCardDtoFromJson(json);
}
