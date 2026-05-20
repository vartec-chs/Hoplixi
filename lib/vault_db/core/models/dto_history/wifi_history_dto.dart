import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/wifi/wifi_items.dart';
import 'vault_snapshot_base_dto.dart';

part 'wifi_history_dto.freezed.dart';
part 'wifi_history_dto.g.dart';

@freezed
sealed class WifiHistoryDataDto with _$WifiHistoryDataDto {
  const factory WifiHistoryDataDto({
    required String ssid,
    String? password,
    WifiSecurityType? securityType,
    String? securityTypeOther,
    WifiEncryptionType? encryption,
    String? encryptionOther,
    @Default(false) bool hiddenSsid,
  }) = _WifiHistoryDataDto;

  factory WifiHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$WifiHistoryDataDtoFromJson(json);
}

@freezed
sealed class WifiHistoryViewDto with _$WifiHistoryViewDto {
  const factory WifiHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required WifiHistoryDataDto wifi,
  }) = _WifiHistoryViewDto;

  factory WifiHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$WifiHistoryViewDtoFromJson(json);
}

@freezed
sealed class WifiHistoryCardDataDto with _$WifiHistoryCardDataDto {
  const factory WifiHistoryCardDataDto({
    required String ssid,
    WifiSecurityType? securityType,
    String? securityTypeOther,
    WifiEncryptionType? encryption,
    String? encryptionOther,
    @Default(false) bool hiddenSsid,
    required bool hasPassword,
  }) = _WifiHistoryCardDataDto;

  factory WifiHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$WifiHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class WifiHistoryCardDto with _$WifiHistoryCardDto {
  const factory WifiHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required WifiHistoryCardDataDto wifi,
  }) = _WifiHistoryCardDto;

  factory WifiHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$WifiHistoryCardDtoFromJson(json);
}
