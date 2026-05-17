import '../../../tables/wifi/wifi_items.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'wifi_history_card_dto.freezed.dart';
part 'wifi_history_card_dto.g.dart';

@freezed
sealed class WifiHistoryCardDataDto with _$WifiHistoryCardDataDto {
  const factory WifiHistoryCardDataDto({
    String? ssid,
    WifiSecurityType? securityType,
    WifiEncryptionType? encryption,
    bool? hiddenSsid,
    @Default(false) bool hasPassword,
  }) = _WifiHistoryCardDataDto;

  factory WifiHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$WifiHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class WifiHistoryCardDto
    with _$WifiHistoryCardDto
    implements VaultHistoryCardDto {
  const factory WifiHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required WifiHistoryCardDataDto wifi,
  }) = _WifiHistoryCardDto;

  factory WifiHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$WifiHistoryCardDtoFromJson(json);
}
