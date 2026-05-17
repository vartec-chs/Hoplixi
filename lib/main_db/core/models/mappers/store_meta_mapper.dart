import '../../main_store.dart';
import '../dto/store_meta_dto.dart';

extension StoreMetaDataMapper on StoreMetaData {
  StoreMetaDto toDto() {
    return StoreMetaDto(
      id: id,
      name: name,
      description: description,
      passwordHash: passwordHash,
      salt: salt,
      attachmentKey: attachmentKey,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      lastOpenedAt: lastOpenedAt,
    );
  }
}
