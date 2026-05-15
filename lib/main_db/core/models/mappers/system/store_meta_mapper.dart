import '../../../main_store.dart';
import '../../dto/system/store_meta_dto.dart';

extension StoreMetaDataMapper on StoreMetaData {
  StoreMetaDto toStoreMetaDto() {
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
