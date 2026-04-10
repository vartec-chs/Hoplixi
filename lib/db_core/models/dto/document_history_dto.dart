import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_history_dto.freezed.dart';
part 'document_history_dto.g.dart';

/// DTO для создания записи истории документа
@freezed
sealed class CreateDocumentHistoryDto with _$CreateDocumentHistoryDto {
  const factory CreateDocumentHistoryDto({
    required String originalDocumentId,
    required String action,
    required String title,
    String? documentType,
    String? description,
    String? aggregatedText,
    int? pageCount,
    String? categoryName,
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
    DateTime? originalLastAccessedAt,
  }) = _CreateDocumentHistoryDto;

  factory CreateDocumentHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$CreateDocumentHistoryDtoFromJson(json);
}

/// DTO для получения записи из истории документа
@freezed
sealed class GetDocumentHistoryDto with _$GetDocumentHistoryDto {
  const factory GetDocumentHistoryDto({
    required String id,
    required String originalDocumentId,
    required String action,
    required String title,
    String? documentType,
    String? description,
    String? aggregatedText,
    int? pageCount,
    String? categoryName,
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
    required DateTime actionAt,
  }) = _GetDocumentHistoryDto;

  factory GetDocumentHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$GetDocumentHistoryDtoFromJson(json);
}

/// DTO для карточки истории документа (основная информация)
@freezed
sealed class DocumentHistoryCardDto with _$DocumentHistoryCardDto {
  const factory DocumentHistoryCardDto({
    required String id,
    required String originalDocumentId,
    required String action,
    required String title,
    String? documentType,
    required DateTime actionAt,
  }) = _DocumentHistoryCardDto;

  factory DocumentHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentHistoryCardDtoFromJson(json);
}
