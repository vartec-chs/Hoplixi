import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'file_dto.freezed.dart';
part 'file_dto.g.dart';

/// DTO для создания нового файла
@freezed
sealed class CreateFileDto with _$CreateFileDto {
  const factory CreateFileDto({
    required String name,
    String? description,
    String?
    metadataId, // ID существующих метаданных или null для создания новых
    // Поля для создания FileMetadata (если metadataId == null)
    String? fileName,
    String? fileExtension,
    String? filePath,
    String? mimeType,
    int? fileSize,
    String? fileHash,
    // Связи
    String? noteId,
    String? categoryId,
    required List<String> tagsIds,
  }) = _CreateFileDto;

  factory CreateFileDto.fromJson(Map<String, dynamic> json) =>
      _$CreateFileDtoFromJson(json);
}

/// DTO для получения полной информации о файле
@freezed
sealed class GetFileDto with _$GetFileDto {
  const factory GetFileDto({
    required String id,
    required String name,
    String? description,
    String? metadataId,
    // Поля из FileMetadata (если загружены)
    String? fileName,
    String? fileExtension,
    String? filePath,
    String? mimeType,
    int? fileSize,
    String? fileHash,
    // Связи
    String? noteId,
    String? categoryId,
    String? categoryName,
    // Системные поля Files
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime createdAt,
    required DateTime modifiedAt,
    DateTime? lastAccessedAt,
    required List<String> tags,
  }) = _GetFileDto;

  factory GetFileDto.fromJson(Map<String, dynamic> json) =>
      _$GetFileDtoFromJson(json);
}

/// DTO для карточки файла (основная информация для отображения)
@freezed
sealed class FileCardDto with _$FileCardDto implements BaseCardDto {
  const factory FileCardDto({
    required String id,
    required String name,
    String? metadataId,
    // Поля из FileMetadata (могут быть null если метаданные не загружены)
    String? fileName,
    String? fileExtension,
    int? fileSize,
    // Системные поля Files
    required bool isFavorite,
    required bool isPinned,
    required bool isArchived,
    required bool isDeleted,
    required int usedCount,
    required DateTime modifiedAt,
    CategoryInCardDto? category,
    List<TagInCardDto>? tags,
  }) = _FileCardDto;

  factory FileCardDto.fromJson(Map<String, dynamic> json) =>
      _$FileCardDtoFromJson(json);
}

/// DTO для обновления файла
@freezed
sealed class UpdateFileDto with _$UpdateFileDto {
  const factory UpdateFileDto({
    String? name,
    String? description,
    String? noteId,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    List<String>? tagsIds,
  }) = _UpdateFileDto;

  factory UpdateFileDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateFileDtoFromJson(json);
}
