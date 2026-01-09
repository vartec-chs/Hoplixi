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
    required String fileName,
    required String fileExtension,
    String? filePath,
    required String mimeType,
    required int fileSize,
    required String fileHash,
    String? description,
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
    required String fileName,
    required String fileExtension,
    required String filePath,
    required String mimeType,
    required int fileSize,
    required String fileHash,
    String? description,
    String? noteId,
    String? categoryId,
    String? categoryName,
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
    required String fileName,
    required String fileExtension,
    required int fileSize,
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
