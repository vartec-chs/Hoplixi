import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'document_dto.freezed.dart';
part 'document_dto.g.dart';

/// DTO для создания нового документа
@freezed
sealed class CreateDocumentDto with _$CreateDocumentDto {
  const factory CreateDocumentDto({
    required String title,
    String? documentType,
    String? description,
    String? aggregatedText,
    String? aggregateHash,
    @Default(0) int pageCount,
    String? categoryId,
    String? noteId,
    required List<String> tagsIds,
  }) = _CreateDocumentDto;

  factory CreateDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$CreateDocumentDtoFromJson(json);
}

/// DTO для получения полной информации о документе
@freezed
sealed class GetDocumentDto with _$GetDocumentDto {
  const factory GetDocumentDto({
    required String id,
    String? title,
    String? documentType,
    String? description,
    String? aggregatedText,
    String? aggregateHash,
    required int pageCount,
    String? categoryId,
    String? categoryName,
    String? noteId,
    String? noteName,
    // Системные поля
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime createdAt,
    required DateTime modifiedAt,
    double? recentScore,
    DateTime? lastUsedAt,
    required List<String> tags,
  }) = _GetDocumentDto;

  factory GetDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$GetDocumentDtoFromJson(json);
}

/// DTO для карточки документа (основная информация для отображения)
@freezed
sealed class DocumentCardDto with _$DocumentCardDto implements BaseCardDto {
  const factory DocumentCardDto({
    required String id,
    String? title,
    String? documentType,
    String? description,
    required int pageCount,
    // Системные поля
    required bool isFavorite,
    required bool isPinned,
    required bool isArchived,
    required bool isDeleted,
    required int usedCount,
    required DateTime modifiedAt,
    CategoryInCardDto? category,
    String? noteId,
    String? noteName,
    List<TagInCardDto>? tags,
  }) = _DocumentCardDto;

  factory DocumentCardDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentCardDtoFromJson(json);
}

/// DTO для обновления документа
@freezed
sealed class UpdateDocumentDto with _$UpdateDocumentDto {
  const factory UpdateDocumentDto({
    String? title,
    String? documentType,
    String? description,
    String? aggregatedText,
    String? aggregateHash,
    int? pageCount,
    String? categoryId,
    String? noteId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    List<String>? tagsIds,
  }) = _UpdateDocumentDto;

  factory UpdateDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateDocumentDtoFromJson(json);
}
