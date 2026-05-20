import 'package:hoplixi/vault_db/core/vault_db.dart';

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
