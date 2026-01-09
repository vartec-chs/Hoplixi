import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_history_dto.freezed.dart';
part 'file_history_dto.g.dart';

/// DTO для создания записи истории файла
@freezed
sealed class CreateFileHistoryDto with _$CreateFileHistoryDto {
  const factory CreateFileHistoryDto({
    required String originalFileId,
    required String action,
    required String name,
    required String fileName,
    required String fileExtension,
    required String filePath,
    required String mimeType,
    required int fileSize,
    required String fileHash,
    String? description,
    String? noteId,
    String? categoryName,
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
    DateTime? originalLastAccessedAt,
  }) = _CreateFileHistoryDto;

  factory CreateFileHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$CreateFileHistoryDtoFromJson(json);
}

/// DTO для получения записи из истории файла
@freezed
sealed class GetFileHistoryDto with _$GetFileHistoryDto {
  const factory GetFileHistoryDto({
    required String id,
    required String originalFileId,
    required String action,
    required String name,
    required String fileName,
    required String fileExtension,
    required String filePath,
    required String mimeType,
    required int fileSize,
    required String fileHash,
    String? description,
    String? noteId,
    String? categoryName,
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
    required DateTime actionAt,
  }) = _GetFileHistoryDto;

  factory GetFileHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$GetFileHistoryDtoFromJson(json);
}

/// DTO для карточки истории файла (основная информация)
@freezed
sealed class FileHistoryCardDto with _$FileHistoryCardDto {
  const factory FileHistoryCardDto({
    required String id,
    required String originalFileId,
    required String action,
    required String name,
    required String fileName,
    required String fileExtension,
    required DateTime actionAt,
  }) = _FileHistoryCardDto;

  factory FileHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$FileHistoryCardDtoFromJson(json);
}
