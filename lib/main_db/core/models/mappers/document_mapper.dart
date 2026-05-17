import '../../main_store.dart';
import '../dto/document_dto.dart';

extension DocumentItemsDataMapper on DocumentItemsData {
  DocumentDataDto toDocumentDataDto() {
    return DocumentDataDto(currentVersionId: currentVersionId);
  }

  DocumentCardDataDto toDocumentCardDataDto() {
    return DocumentCardDataDto(
      currentVersionId: currentVersionId,
      hasCurrentVersion: currentVersionId != null,
    );
  }
}

extension DocumentVersionsDataMapper on DocumentVersionsData {
  DocumentVersionViewDto toDocumentVersionViewDto() {
    return DocumentVersionViewDto(
      id: id,
      documentId: documentId,
      historyId: historyId,
      versionNumber: versionNumber,
      documentType: documentType,
      documentTypeOther: documentTypeOther,
      aggregateSha256Hash: aggregateSha256Hash,
      pageCount: pageCount,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }

  DocumentVersionCardDto toDocumentVersionCardDto() {
    return DocumentVersionCardDto(
      id: id,
      documentId: documentId,
      versionNumber: versionNumber,
      documentType: documentType,
      documentTypeOther: documentTypeOther,
      pageCount: pageCount,
      createdAt: createdAt,
    );
  }
}

extension DocumentVersionPagesDataMapper on DocumentVersionPagesData {
  DocumentVersionPageViewDto toDocumentVersionPageViewDto() {
    return DocumentVersionPageViewDto(
      id: id,
      versionId: versionId,
      metadataHistoryId: metadataHistoryId,
      pageNumber: pageNumber,
      pageSha256Hash: pageSha256Hash,
      isPrimary: isPrimary,
      createdAt: createdAt,
    );
  }

  DocumentVersionPageCardDto toDocumentVersionPageCardDto() {
    return DocumentVersionPageCardDto(
      id: id,
      versionId: versionId,
      pageNumber: pageNumber,
      isPrimary: isPrimary,
    );
  }
}

extension DocumentPagesDataMapper on DocumentPagesData {
  DocumentPageViewDto toDocumentPageViewDto() {
    return DocumentPageViewDto(
      id: id,
      documentId: documentId,
      currentVersionPageId: currentVersionPageId,
    );
  }

  DocumentPageCardDto toDocumentPageCardDto() {
    return DocumentPageCardDto(
      id: id,
      documentId: documentId,
      currentVersionPageId: currentVersionPageId,
    );
  }
}
