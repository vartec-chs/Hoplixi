import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault_item_base_dto.dart';

part 'note_dto.freezed.dart';
part 'note_dto.g.dart';

@freezed
sealed class NoteDataDto with _$NoteDataDto {
  const factory NoteDataDto({
    required String deltaJson,
    required String content,
  }) = _NoteDataDto;

  factory NoteDataDto.fromJson(Map<String, dynamic> json) =>
      _$NoteDataDtoFromJson(json);
}

@freezed
sealed class NoteCardDataDto with _$NoteCardDataDto {
  const factory NoteCardDataDto({
    required String content,
  }) = _NoteCardDataDto;

  factory NoteCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$NoteCardDataDtoFromJson(json);
}

@freezed
sealed class CreateNoteDto with _$CreateNoteDto {
  const factory CreateNoteDto({
    required VaultItemCreateDto item,
    required NoteDataDto note,
  }) = _CreateNoteDto;

  factory CreateNoteDto.fromJson(Map<String, dynamic> json) =>
      _$CreateNoteDtoFromJson(json);
}

@freezed
sealed class UpdateNoteDto with _$UpdateNoteDto {
  const factory UpdateNoteDto({
    required VaultItemUpdateDto item,
    required NoteDataDto note,
  }) = _UpdateNoteDto;

  factory UpdateNoteDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateNoteDtoFromJson(json);
}

@freezed
sealed class NoteViewDto with _$NoteViewDto {
  const factory NoteViewDto({
    required VaultItemViewDto item,
    required NoteDataDto note,
  }) = _NoteViewDto;

  factory NoteViewDto.fromJson(Map<String, dynamic> json) =>
      _$NoteViewDtoFromJson(json);
}

@freezed
sealed class NoteCardDto with _$NoteCardDto {
  const factory NoteCardDto({
    required VaultItemCardDto item,
    required NoteCardDataDto note,
  }) = _NoteCardDto;

  factory NoteCardDto.fromJson(Map<String, dynamic> json) =>
      _$NoteCardDtoFromJson(json);
}
