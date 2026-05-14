import 'package:hoplixi/main_db/core/models/dto/document_dto.dart';
import '../../main_store.dart';

extension DocumentItemsDataMapper on DocumentItemsData {
  DocumentDataDto toDocumentDataDto() {
    return DocumentDataDto(
      documentType: documentType,
      documentTypeOther: documentTypeOther,
      documentNumber: documentNumber,
      issueDate: issueDate,
      expiryDate: expiryDate,
      issuingAuthority: issuingAuthority,
      issuingCountry: issuingCountry,
      currentVersionId: currentVersionId,
    );
  }

  DocumentCardDataDto toDocumentCardDataDto() {
    return DocumentCardDataDto(
      documentType: documentType,
      documentNumber: documentNumber,
      expiryDate: expiryDate,
      issuingAuthority: issuingAuthority,
      issuingCountry: issuingCountry,
      hasVersions: currentVersionId != null,
    );
  }
}
