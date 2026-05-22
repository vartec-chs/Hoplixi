import 'package:hoplixi/vault_db/core/vault_db.dart';
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
