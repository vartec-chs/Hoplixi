import 'package:hoplixi/main_db/core/models/dto/file_dto.dart';
import '../../main_store.dart';

extension FileItemsDataMapper on FileItemsData {
  FileDataDto toFileDataDto() {
    return FileDataDto(
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      extension: extension,
      blobId: blobId,
      metadataId: metadataId,
      thumbnailBlobId: thumbnailBlobId,
    );
  }

  FileCardDataDto toFileCardDataDto() {
    return FileCardDataDto(
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      extension: extension,
      hasThumbnail: thumbnailBlobId != null,
    );
  }
}
