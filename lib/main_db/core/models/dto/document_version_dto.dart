import 'package:hoplixi/main_db/core/tables/tables.dart';


class CreateDocumentVersionPageDto {
  const CreateDocumentVersionPageDto({
    this.pageId,
    this.metadataHistoryId,
    required this.pageNumber,
    this.pageSha256Hash,
    this.isPrimary = false,
  });

  /// Stable document_pages.id.
  /// If null, service creates new document_pages row.
  final String? pageId;

  final String? metadataHistoryId;
  final int pageNumber;
  final String? pageSha256Hash;
  final bool isPrimary;
}

class CreateDocumentVersionDto {
  const CreateDocumentVersionDto({
    required this.documentId,
    this.historyId,
    this.documentType,
    this.documentTypeOther,
    this.aggregateSha256Hash,
    required this.pages,
    this.activate = true,
  });

  final String documentId;
  final String? historyId;
  final DocumentType? documentType;
  final String? documentTypeOther;
  final String? aggregateSha256Hash;
  final List<CreateDocumentVersionPageDto> pages;
  final bool activate;
}

class DocumentVersionPageViewDto {
  const DocumentVersionPageViewDto({
    required this.id,
    required this.versionId,
    required this.pageId,
    this.metadataHistoryId,
    required this.pageNumber,
    this.pageSha256Hash,
    required this.isPrimary,
    required this.createdAt,
  });

  final String id;
  final String versionId;
  final String pageId;
  final String? metadataHistoryId;
  final int pageNumber;
  final String? pageSha256Hash;
  final bool isPrimary;
  final DateTime createdAt;
}

class DocumentVersionViewDto {
  const DocumentVersionViewDto({
    required this.id,
    required this.documentId,
    this.historyId,
    required this.versionNumber,
    this.documentType,
    this.documentTypeOther,
    this.aggregateSha256Hash,
    required this.pageCount,
    required this.createdAt,
    required this.modifiedAt,
    required this.pages,
    required this.isCurrent,
  });

  final String id;
  final String documentId;
  final String? historyId;
  final int versionNumber;
  final DocumentType? documentType;
  final String? documentTypeOther;
  final String? aggregateSha256Hash;
  final int pageCount;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final List<DocumentVersionPageViewDto> pages;
  final bool isCurrent;
}

class DocumentVersionCardDto {
  const DocumentVersionCardDto({
    required this.id,
    required this.documentId,
    this.historyId,
    required this.versionNumber,
    this.documentType,
    this.documentTypeOther,
    this.aggregateSha256Hash,
    required this.pageCount,
    required this.createdAt,
    required this.modifiedAt,
    required this.isCurrent,
  });

  final String id;
  final String documentId;
  final String? historyId;
  final int versionNumber;
  final DocumentType? documentType;
  final String? documentTypeOther;
  final String? aggregateSha256Hash;
  final int pageCount;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isCurrent;
}
