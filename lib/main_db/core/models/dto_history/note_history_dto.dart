import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault_snapshot_base_dto.dart';

part 'note_history_dto.freezed.dart';
part 'note_history_dto.g.dart';

@freezed
sealed class NoteHistoryDataDto with _$NoteHistoryDataDto {
  const factory NoteHistoryDataDto({
    String? deltaJson,
    String? content,
  }) = _NoteHistoryDataDto;

  factory NoteHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$NoteHistoryDataDtoFromJson(json);
}

@freezed
sealed class NoteHistoryViewDto with _$NoteHistoryViewDto {
  const factory NoteHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required NoteHistoryDataDto note,
  }) = _NoteHistoryViewDto;

  factory NoteHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$NoteHistoryViewDtoFromJson(json);
}

@freezed
sealed class NoteHistoryCardDataDto with _$NoteHistoryCardDataDto {
  const factory NoteHistoryCardDataDto({
    String? content,
    required bool hasDelta,
  }) = _NoteHistoryCardDataDto;

  factory NoteHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$NoteHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class NoteHistoryCardDto with _$NoteHistoryCardDto {
  const factory NoteHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required NoteHistoryCardDataDto note,
  }) = _NoteHistoryCardDto;

  factory NoteHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$NoteHistoryCardDtoFromJson(json);
}
