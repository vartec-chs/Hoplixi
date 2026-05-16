import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';
import '../../../tables/vault_items/vault_items.dart'; // or enums
import '../../../tables/api_key/api_key_items.dart'; // for enums
import '../../../tables/bank_card/bank_card_items.dart';
import '../../../tables/certificate/certificate_items.dart';
import '../../../tables/crypto_wallet/crypto_wallet_items.dart';
import '../../../tables/license_key/license_key_items.dart';
import '../../../tables/loyalty_card/loyalty_card_items.dart';
import '../../../tables/otp/otp_items.dart';
import '../../../tables/ssh_key/ssh_key_items.dart';
import '../../../tables/wifi/wifi_items.dart';
import '../../../tables/file/file_metadata.dart';
import 'dart:typed_data';

part 'note_history_card_dto.freezed.dart';
part 'note_history_card_dto.g.dart';

@freezed
sealed class NoteHistoryCardDataDto with _$NoteHistoryCardDataDto {
  const factory NoteHistoryCardDataDto({
    String? deltaJson,
    String? content,
  }) = _NoteHistoryCardDataDto;

  factory NoteHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$NoteHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class NoteHistoryCardDto with _$NoteHistoryCardDto implements VaultHistoryCardDto {
  const factory NoteHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required NoteHistoryCardDataDto note,
  }) = _NoteHistoryCardDto;

  factory NoteHistoryCardDto.fromJson(Map<String, dynamic> json) => _$NoteHistoryCardDtoFromJson(json);
}
