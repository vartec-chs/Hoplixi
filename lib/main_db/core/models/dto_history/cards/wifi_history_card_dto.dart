import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';
import '../../../tables/vault_items/vault_items.dart'; // or enums
import '../../../tables/api_key/api_key_items.dart'; // for enums
import '../../../tables/bank_card/bank_card_items.dart';
import '../../../tables/certificate/certificate_items.dart';
import '../../../tables/crypto_wallet/crypto_wallet_items.dart';
import '../../../tables/license_key/license_key_items.dart';
import '../../../tables/loyalty_card/loyalty_card_items.dart';
import '../../../tables/otp/otp_items.dart';
import '../../../tables/ssh_key/ssh_key_items.dart';
import '../../../tables/wifi/wifi_items.dart';
import '../../../tables/file/file_metadata.dart';
import 'dart:typed_data';

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

  factory WifiHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$WifiHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class WifiHistoryCardDto with _$WifiHistoryCardDto implements VaultHistoryCardDto {
  const factory WifiHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required WifiHistoryCardDataDto wifi,
  }) = _WifiHistoryCardDto;

  factory WifiHistoryCardDto.fromJson(Map<String, dynamic> json) => _$WifiHistoryCardDtoFromJson(json);
}
