import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_history_dto.freezed.dart';
part 'note_history_dto.g.dart';

/// DTO для создания записи истории заметки
@freezed
sealed class CreateNoteHistoryDto with _$CreateNoteHistoryDto {
  const factory CreateNoteHistoryDto({
    required String originalNoteId,
    required String action,
    required String title,
    required String content,
    required String deltaJson,
    String? description,
    String? categoryName,
    int? usedCount,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    bool? isDeleted,
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
  }) = _CreateNoteHistoryDto;

  factory CreateNoteHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$CreateNoteHistoryDtoFromJson(json);
}

/// DTO для получения записи из истории заметки
@freezed
sealed class GetNoteHistoryDto with _$GetNoteHistoryDto {
  const factory GetNoteHistoryDto({
    required String id,
    required String originalNoteId,
    required String action,
    required String title,
    String? description,
    required String content,
    required String deltaJson,
    String? categoryName,
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
    required DateTime actionAt,
  }) = _GetNoteHistoryDto;

  factory GetNoteHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$GetNoteHistoryDtoFromJson(json);
}

/// DTO для карточки истории заметки (основная информация)
@freezed
sealed class NoteHistoryCardDto with _$NoteHistoryCardDto {
  const factory NoteHistoryCardDto({
    required String id,
    required String originalNoteId,
    required String action,
    required String title,
    String? description,
    required DateTime actionAt,
  }) = _NoteHistoryCardDto;

  factory NoteHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$NoteHistoryCardDtoFromJson(json);
}
