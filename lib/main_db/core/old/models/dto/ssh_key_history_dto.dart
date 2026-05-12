import 'package:freezed_annotation/freezed_annotation.dart';

part 'ssh_key_history_dto.freezed.dart';
part 'ssh_key_history_dto.g.dart';

@freezed
sealed class SshKeyHistoryCardDto with _$SshKeyHistoryCardDto {
  const factory SshKeyHistoryCardDto({
    required String id,
    required String originalSshKeyId,
    required String action,
    required String name,
    String? keyType,
    String? fingerprint,
    bool? addedToAgent,
    String? usage,
    required DateTime actionAt,
  }) = _SshKeyHistoryCardDto;

  factory SshKeyHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$SshKeyHistoryCardDtoFromJson(json);
}
