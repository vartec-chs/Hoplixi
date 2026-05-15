import '../../../main_store.dart';
import '../../dto/system/store_settings_dto.dart';

extension StoreSettingDataMapper on StoreSettingData {
  StoreSettingDto toStoreSettingDto() {
    return StoreSettingDto(
      key: key,
      value: value,
      valueType: valueType,
      description: description,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }
}
