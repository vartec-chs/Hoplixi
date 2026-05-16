import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

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