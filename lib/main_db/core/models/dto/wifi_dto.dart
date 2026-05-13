import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/wifi/wifi_items.dart';
import 'vault_item_base_dto.dart';

part 'wifi_dto.freezed.dart';
part 'wifi_dto.g.dart';

@freezed
sealed class WifiDataDto with _$WifiDataDto {
  const factory WifiDataDto({
    required String ssid,
    String? password,
    WifiSecurityType? securityType,
    String? securityTypeOther,
    WifiEncryptionType? encryption,
    String? encryptionOther,
    @Default(false) bool hiddenSsid,
  }) = _WifiDataDto;

  factory WifiDataDto.fromJson(Map<String, dynamic> json) =>
      _$WifiDataDtoFromJson(json);
}

@freezed
sealed class WifiCardDataDto with _$WifiCardDataDto {
  const factory WifiCardDataDto({
    required String ssid,
    WifiSecurityType? securityType,
    WifiEncryptionType? encryption,
    @Default(false) bool hiddenSsid,
    @Default(false) bool hasWifiPassword,
  }) = _WifiCardDataDto;

  factory WifiCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$WifiCardDataDtoFromJson(json);
}

@freezed
sealed class CreateWifiDto with _$CreateWifiDto {
  const factory CreateWifiDto({
    required VaultItemCreateDto item,
    required WifiDataDto wifi,
  }) = _CreateWifiDto;

  factory CreateWifiDto.fromJson(Map<String, dynamic> json) =>
      _$CreateWifiDtoFromJson(json);
}

@freezed
sealed class UpdateWifiDto with _$UpdateWifiDto {
  const factory UpdateWifiDto({
    required VaultItemUpdateDto item,
    required WifiDataDto wifi,
  }) = _UpdateWifiDto;

  factory UpdateWifiDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateWifiDtoFromJson(json);
}

@freezed
sealed class WifiViewDto with _$WifiViewDto {
  const factory WifiViewDto({
    required VaultItemViewDto item,
    required WifiDataDto wifi,
  }) = _WifiViewDto;

  factory WifiViewDto.fromJson(Map<String, dynamic> json) =>
      _$WifiViewDtoFromJson(json);
}

@freezed
sealed class WifiCardDto with _$WifiCardDto {
  const factory WifiCardDto({
    required VaultItemCardDto item,
    required WifiCardDataDto wifi,
  }) = _WifiCardDto;

  factory WifiCardDto.fromJson(Map<String, dynamic> json) =>
      _$WifiCardDtoFromJson(json);
}
