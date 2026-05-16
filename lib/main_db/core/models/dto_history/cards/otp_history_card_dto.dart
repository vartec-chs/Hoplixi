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

part 'otp_history_card_dto.freezed.dart';
part 'otp_history_card_dto.g.dart';

@freezed
sealed class OtpHistoryCardDataDto with _$OtpHistoryCardDataDto {
  const factory OtpHistoryCardDataDto({
    OtpType? type,
    String? issuer,
    String? accountName,
    OtpHashAlgorithm? algorithm,
    int? digits,
    int? period,
    int? counter,
    @Default(false) bool hasSecret,
  }) = _OtpHistoryCardDataDto;

  factory OtpHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$OtpHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class OtpHistoryCardDto with _$OtpHistoryCardDto implements VaultHistoryCardDto {
  const factory OtpHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required OtpHistoryCardDataDto otp,
  }) = _OtpHistoryCardDto;

  factory OtpHistoryCardDto.fromJson(Map<String, dynamic> json) => _$OtpHistoryCardDtoFromJson(json);
}
