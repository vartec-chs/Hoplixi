import '../../../tables/ssh_key/ssh_key_items.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'ssh_key_history_card_dto.freezed.dart';
part 'ssh_key_history_card_dto.g.dart';

@freezed
sealed class SshKeyHistoryCardDataDto with _$SshKeyHistoryCardDataDto {
  const factory SshKeyHistoryCardDataDto({
    String? publicKey,
    SshKeyType? keyType,
    int? keySize,
    @Default(false) bool hasPrivateKey,
  }) = _SshKeyHistoryCardDataDto;

  factory SshKeyHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$SshKeyHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class SshKeyHistoryCardDto with _$SshKeyHistoryCardDto implements VaultHistoryCardDto {
  const factory SshKeyHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required SshKeyHistoryCardDataDto sshkey,
  }) = _SshKeyHistoryCardDto;

  factory SshKeyHistoryCardDto.fromJson(Map<String, dynamic> json) => _$SshKeyHistoryCardDtoFromJson(json);
}