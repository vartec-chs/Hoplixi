import 'package:freezed_annotation/freezed_annotation.dart';
import '../../tables/document/document_types.dart';
import 'vault_item_base_dto.dart';

part 'document_dto.freezed.dart';
part 'document_dto.g.dart';

@freezed
sealed class DocumentDataDto with _$DocumentDataDto {
  const factory DocumentDataDto({
    String? currentVersionId,
  }) = _DocumentDataDto;

  factory DocumentDataDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentDataDtoFromJson(json);
}

@freezed
sealed class DocumentCardDataDto with _$DocumentCardDataDto {
  const factory DocumentCardDataDto({
    String? currentVersionId,
    required bool hasCurrentVersion,
  }) = _DocumentCardDataDto;

  factory DocumentCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentCardDataDtoFromJson(json);
}

@freezed
sealed class DocumentCurrentVersionCardDataDto
    with _$DocumentCurrentVersionCardDataDto {
  const factory DocumentCurrentVersionCardDataDto({
    String? currentVersionId,
    int? currentVersionNumber,
    DocumentType? documentType,
    String? documentTypeOther,
    int? pageCount,
    DateTime? versionCreatedAt,
    DateTime? versionModifiedAt,
    required bool hasCurrentVersion,
  }) = _DocumentCurrentVersionCardDataDto;

  factory DocumentCurrentVersionCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentCurrentVersionCardDataDtoFromJson(json);
}

@freezed
sealed class CreateDocumentDto with _$CreateDocumentDto {
  const factory CreateDocumentDto({
    required VaultItemCreateDto item,
    @Default(DocumentDataDto()) DocumentDataDto document,
  }) = _CreateDocumentDto;

  factory CreateDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$CreateDocumentDtoFromJson(json);
}

@freezed
sealed class UpdateDocumentDto with _$UpdateDocumentDto {
  const factory UpdateDocumentDto({
    required VaultItemUpdateDto item,
    required DocumentDataDto document,
  }) = _UpdateDocumentDto;

  factory UpdateDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateDocumentDtoFromJson(json);
}

@freezed
sealed class DocumentViewDto with _$DocumentViewDto {
  const factory DocumentViewDto({
    required VaultItemViewDto item,
    required DocumentDataDto document,
  }) = _DocumentViewDto;

  factory DocumentViewDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentViewDtoFromJson(json);
}

@freezed
sealed class DocumentCardDto with _$DocumentCardDto {
  const factory DocumentCardDto({
    required VaultItemCardDto item,
    required DocumentCurrentVersionCardDataDto document,
  }) = _DocumentCardDto;

  factory DocumentCardDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentCardDtoFromJson(json);
}

// --- Versions ---

@freezed
sealed class DocumentVersionDataDto with _$DocumentVersionDataDto {
  const factory DocumentVersionDataDto({
    String? historyId,
    required int versionNumber,
    DocumentType? documentType,
    String? documentTypeOther,
    String? aggregateSha256Hash,
    @Default(0) int pageCount,
  }) = _DocumentVersionDataDto;

  factory DocumentVersionDataDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentVersionDataDtoFromJson(json);
}

@freezed
sealed class CreateDocumentVersionDto with _$CreateDocumentVersionDto {
  const factory CreateDocumentVersionDto({
    required String documentId,
    required DocumentVersionDataDto version,
    @Default([]) List<CreateDocumentVersionPageDto> pages,
    @Default(true) bool setAsCurrent,
  }) = _CreateDocumentVersionDto;

  factory CreateDocumentVersionDto.fromJson(Map<String, dynamic> json) =>
      _$CreateDocumentVersionDtoFromJson(json);
}

@freezed
sealed class UpdateDocumentVersionDto with _$UpdateDocumentVersionDto {
  const factory UpdateDocumentVersionDto({
    required String id,
    DocumentType? documentType,
    String? documentTypeOther,
    String? aggregateSha256Hash,
  }) = _UpdateDocumentVersionDto;

  factory UpdateDocumentVersionDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateDocumentVersionDtoFromJson(json);
}

@freezed
sealed class DocumentVersionViewDto with _$DocumentVersionViewDto {
  const factory DocumentVersionViewDto({
    required String id,
    required String documentId,
    String? historyId,
    required int versionNumber,
    DocumentType? documentType,
    String? documentTypeOther,
    String? aggregateSha256Hash,
    required int pageCount,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _DocumentVersionViewDto;

  factory DocumentVersionViewDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentVersionViewDtoFromJson(json);
}

@freezed
sealed class DocumentVersionCardDto with _$DocumentVersionCardDto {
  const factory DocumentVersionCardDto({
    required String id,
    required String documentId,
    required int versionNumber,
    DocumentType? documentType,
    String? documentTypeOther,
    required int pageCount,
    required DateTime createdAt,
  }) = _DocumentVersionCardDto;

  factory DocumentVersionCardDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentVersionCardDtoFromJson(json);
}

// --- Version Pages ---

@freezed
sealed class DocumentVersionPageDataDto with _$DocumentVersionPageDataDto {
  const factory DocumentVersionPageDataDto({
    required String versionId,
    String? metadataHistoryId,
    required int pageNumber,
    String? pageSha256Hash,
    @Default(false) bool isPrimary,
  }) = _DocumentVersionPageDataDto;

  factory DocumentVersionPageDataDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentVersionPageDataDtoFromJson(json);
}

@freezed
sealed class CreateDocumentVersionPageDto with _$CreateDocumentVersionPageDto {
  const factory CreateDocumentVersionPageDto({
    String? metadataHistoryId,
    required int pageNumber,
    String? pageSha256Hash,
    @Default(false) bool isPrimary,
  }) = _CreateDocumentVersionPageDto;

  factory CreateDocumentVersionPageDto.fromJson(Map<String, dynamic> json) =>
      _$CreateDocumentVersionPageDtoFromJson(json);
}

@freezed
sealed class DocumentVersionPageViewDto with _$DocumentVersionPageViewDto {
  const factory DocumentVersionPageViewDto({
    required String id,
    required String versionId,
    String? metadataHistoryId,
    required int pageNumber,
    String? pageSha256Hash,
    required bool isPrimary,
    required DateTime createdAt,
  }) = _DocumentVersionPageViewDto;

  factory DocumentVersionPageViewDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentVersionPageViewDtoFromJson(json);
}

@freezed
sealed class DocumentVersionPageCardDto with _$DocumentVersionPageCardDto {
  const factory DocumentVersionPageCardDto({
    required String id,
    required String versionId,
    required int pageNumber,
    required bool isPrimary,
  }) = _DocumentVersionPageCardDto;

  factory DocumentVersionPageCardDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentVersionPageCardDtoFromJson(json);
}

// --- Live Pages ---

@freezed
sealed class DocumentPageDataDto with _$DocumentPageDataDto {
  const factory DocumentPageDataDto({
    required String documentId,
    String? currentVersionPageId,
  }) = _DocumentPageDataDto;

  factory DocumentPageDataDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentPageDataDtoFromJson(json);
}

@freezed
sealed class CreateDocumentPageDto with _$CreateDocumentPageDto {
  const factory CreateDocumentPageDto({
    required String documentId,
    String? currentVersionPageId,
  }) = _CreateDocumentPageDto;

  factory CreateDocumentPageDto.fromJson(Map<String, dynamic> json) =>
      _$CreateDocumentPageDtoFromJson(json);
}

@freezed
sealed class DocumentPageViewDto with _$DocumentPageViewDto {
  const factory DocumentPageViewDto({
    required String id,
    required String documentId,
    String? currentVersionPageId,
  }) = _DocumentPageViewDto;

  factory DocumentPageViewDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentPageViewDtoFromJson(json);
}

@freezed
sealed class DocumentPageCardDto with _$DocumentPageCardDto {
  const factory DocumentPageCardDto({
    required String id,
    required String documentId,
    String? currentVersionPageId,
  }) = _DocumentPageCardDto;

  factory DocumentPageCardDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentPageCardDtoFromJson(json);
}
