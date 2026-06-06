import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';

import '../../scheme/tables/document/document_types.dart';
import '../field_update.dart';
import 'vault_item_base_dto.dart';

part 'document_dto.freezed.dart';
part 'document_dto.g.dart';

@freezed
sealed class DocumentDataDto with _$DocumentDataDto {
  const factory DocumentDataDto({String? currentVersionId}) = _DocumentDataDto;

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

  factory DocumentCurrentVersionCardDataDto.fromJson(
    Map<String, dynamic> json,
  ) => _$DocumentCurrentVersionCardDataDtoFromJson(json);
}

@freezed
sealed class CreateDocumentDto with _$CreateDocumentDto {
  const factory CreateDocumentDto({
    required VaultItemCreateDto item,
    @Default(DocumentDataDto()) DocumentDataDto document,
    @Default([]) List<String> tagIds,
  }) = _CreateDocumentDto;

  factory CreateDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$CreateDocumentDtoFromJson(json);
}

@freezed
sealed class DocumentViewDto
    with _$DocumentViewDto
    implements VaultEntityViewDto {
  const factory DocumentViewDto({
    required VaultItemViewDto item,
    required DocumentDataDto document,
  }) = _DocumentViewDto;

  factory DocumentViewDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentViewDtoFromJson(json);
}

@freezed
sealed class DocumentCardDto
    with _$DocumentCardDto
    implements VaultEntityCardDto<DocumentCurrentVersionCardDataDto> {
  const DocumentCardDto._();

  const factory DocumentCardDto({
    required VaultItemCardDto item,
    required DocumentCurrentVersionCardDataDto data,
  }) = _DocumentCardDto;

  @override
  VaultItemType get type => VaultItemType.document;

  factory DocumentCardDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentCardDtoFromJson(json);
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

@freezed
sealed class PatchDocumentDataDto with _$PatchDocumentDataDto {
  const factory PatchDocumentDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<String> currentVersionId,
  }) = _PatchDocumentDataDto;
}

@freezed
sealed class PatchDocumentDto with _$PatchDocumentDto {
  const factory PatchDocumentDto({
    required VaultItemPatchDto item,
    required PatchDocumentDataDto document,
    @Default(FieldUpdate.keep()) FieldUpdate<List<String>> tags,
  }) = _PatchDocumentDto;
}
