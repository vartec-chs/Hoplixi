import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../dto/file_dto.dart';

extension FileItemsDataMapper on FileItemsData {
  FileDataDto toFileDataDto() {
    return FileDataDto(metadataId: metadataId);
  }
}

extension FileMetadataDataMapper on FileMetadataData {
  FileMetadataDataDto toFileMetadataDataDto() {
    return FileMetadataDataDto(
      fileName: fileName,
      fileExtension: fileExtension,
      filePath: filePath,
      mimeType: mimeType,
      fileSize: fileSize,
      sha256: sha256,
      availabilityStatus: availabilityStatus,
      integrityStatus: integrityStatus,
      missingDetectedAt: missingDetectedAt,
      deletedAt: deletedAt,
      lastIntegrityCheckAt: lastIntegrityCheckAt,
    );
  }

  FileMetadataViewDto toFileMetadataViewDto() {
    return FileMetadataViewDto(
      id: id,
      fileName: fileName,
      fileExtension: fileExtension,
      filePath: filePath,
      mimeType: mimeType,
      fileSize: fileSize,
      sha256: sha256,
      availabilityStatus: availabilityStatus,
      integrityStatus: integrityStatus,
      missingDetectedAt: missingDetectedAt,
      deletedAt: deletedAt,
      lastIntegrityCheckAt: lastIntegrityCheckAt,
    );
  }
}
