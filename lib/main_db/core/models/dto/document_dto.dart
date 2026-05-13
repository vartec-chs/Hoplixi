import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/document/document_types.dart';

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
