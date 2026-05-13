import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/ssh_key/ssh_key_items.dart';
import 'vault_snapshot_base_dto.dart';

part 'ssh_key_history_dto.freezed.dart';
part 'ssh_key_history_dto.g.dart';

@freezed
sealed class SshKeyHistoryDataDto with _$SshKeyHistoryDataDto {
  const factory SshKeyHistoryDataDto({
    String? publicKey,
    String? privateKey,
    SshKeyType? keyType,
    String? keyTypeOther,
    int? keySize,
  }) = _SshKeyHistoryDataDto;

  factory SshKeyHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$SshKeyHistoryDataDtoFromJson(json);
}

@freezed
sealed class SshKeyHistoryViewDto with _$SshKeyHistoryViewDto {
  const factory SshKeyHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required SshKeyHistoryDataDto sshKey,
  }) = _SshKeyHistoryViewDto;

  factory SshKeyHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$SshKeyHistoryViewDtoFromJson(json);
}

@freezed
sealed class SshKeyHistoryCardDataDto with _$SshKeyHistoryCardDataDto {
  const factory SshKeyHistoryCardDataDto({
    SshKeyType? keyType,
    String? keyTypeOther,
    int? keySize,
    required bool hasPublicKey,
    required bool hasPrivateKey,
  }) = _SshKeyHistoryCardDataDto;

  factory SshKeyHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$SshKeyHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class SshKeyHistoryCardDto with _$SshKeyHistoryCardDto {
  const factory SshKeyHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required SshKeyHistoryCardDataDto sshKey,
  }) = _SshKeyHistoryCardDto;

  factory SshKeyHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$SshKeyHistoryCardDtoFromJson(json);
}
