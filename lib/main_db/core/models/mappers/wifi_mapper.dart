import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/wifi_dto.dart';

extension WifiItemsDataMapper on WifiItemsData {
  WifiDataDto toWifiDataDto() {
    return WifiDataDto(
      ssid: ssid,
      password: password,
      securityType: securityType,
      securityTypeOther: securityTypeOther,
      encryption: encryption,
      encryptionOther: encryptionOther,
      hiddenSsid: hiddenSsid,
    );
  }

  WifiCardDataDto toWifiCardDataDto() {
    return WifiCardDataDto(
      ssid: ssid,
      securityType: securityType,
      encryption: encryption,
      hiddenSsid: hiddenSsid,
      hasWifiPassword: password?.isNotEmpty ?? false,
    );
  }
}
