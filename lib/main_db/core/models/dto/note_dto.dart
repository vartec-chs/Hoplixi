import 'package:freezed_annotation/freezed_annotation.dart';

import '../field_update.dart';
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
    @Default([]) List<String> tagIds,
  }) = _CreateNoteDto;

  factory CreateNoteDto.fromJson(Map<String, dynamic> json) =>
      _$CreateNoteDtoFromJson(json);
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

@freezed
sealed class PatchNoteDataDto with _$PatchNoteDataDto {
  const factory PatchNoteDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<String> deltaJson,
    @Default(FieldUpdate.keep()) FieldUpdate<String> content,
  }) = _PatchNoteDataDto;
}

@freezed
sealed class PatchNoteDto with _$PatchNoteDto {
  const factory PatchNoteDto({
    required VaultItemPatchDto item,
    required PatchNoteDataDto note,
    @Default(FieldUpdate.keep()) FieldUpdate<List<String>> tags,
  }) = _PatchNoteDto;
}
