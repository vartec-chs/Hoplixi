import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/document/document_types.dart';
import 'vault_item_base_dto.dart';

part 'document_dto.freezed.dart';
part 'document_dto.g.dart';

@freezed
sealed class DocumentVersionDto with _$DocumentVersionDto {
  const factory DocumentVersionDto({
    String? id,
    required String documentId,
    String? historyId,
    required int versionNumber,
    DocumentType? documentType,
    String? documentTypeOther,
    String? aggregateSha256Hash,
    @Default(0) int pageCount,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _DocumentVersionDto;

  factory DocumentVersionDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentVersionDtoFromJson(json);
}

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
  }) = _DocumentCardDataDto;

  factory DocumentCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentCardDataDtoFromJson(json);
}

@freezed
sealed class CreateDocumentDto with _$CreateDocumentDto {
  const factory CreateDocumentDto({
    required VaultItemCreateDto item,
    required DocumentDataDto document,
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
    required DocumentCardDataDto document,
  }) = _DocumentCardDto;

  factory DocumentCardDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentCardDtoFromJson(json);
}

@freezed
sealed class DocumentPageDto with _$DocumentPageDto {
  const factory DocumentPageDto({
    String? id,
    required String documentId,
    String? currentVersionPageId,
  }) = _DocumentPageDto;

  factory DocumentPageDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentPageDtoFromJson(json);
}

@freezed
sealed class DocumentVersionPageDto with _$DocumentVersionPageDto {
  const factory DocumentVersionPageDto({
    String? id,
    required String versionId,
    String? metadataHistoryId,
    required int pageNumber,
    String? pageSha256Hash,
    @Default(false) bool isPrimary,
    DateTime? createdAt,
  }) = _DocumentVersionPageDto;

  factory DocumentVersionPageDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentVersionPageDtoFromJson(json);
}

@freezed
sealed class DocumentVersionViewDto with _$DocumentVersionViewDto {
  const factory DocumentVersionViewDto({
    required DocumentVersionDto version,
    @Default([]) List<DocumentVersionPageDto> pages,
  }) = _DocumentVersionViewDto;

  factory DocumentVersionViewDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentVersionViewDtoFromJson(json);
}

@freezed
sealed class DocumentVersionCardDto with _$DocumentVersionCardDto {
  const factory DocumentVersionCardDto({
    required DocumentVersionDto version,
  }) = _DocumentVersionCardDto;

  factory DocumentVersionCardDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentVersionCardDtoFromJson(json);
}
