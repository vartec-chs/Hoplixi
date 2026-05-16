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

part 'identity_history_card_dto.freezed.dart';
part 'identity_history_card_dto.g.dart';

@freezed
sealed class IdentityHistoryCardDataDto with _$IdentityHistoryCardDataDto {
  const factory IdentityHistoryCardDataDto({
    String? firstName,
    String? middleName,
    String? lastName,
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? address,
    DateTime? birthday,
    String? company,
    String? jobTitle,
    String? website,
    String? taxId,
    String? nationalId,
    String? passportNumber,
    String? driverLicenseNumber,
  }) = _IdentityHistoryCardDataDto;

  factory IdentityHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$IdentityHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class IdentityHistoryCardDto with _$IdentityHistoryCardDto implements VaultHistoryCardDto {
  const factory IdentityHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required IdentityHistoryCardDataDto identity,
  }) = _IdentityHistoryCardDto;

  factory IdentityHistoryCardDto.fromJson(Map<String, dynamic> json) => _$IdentityHistoryCardDtoFromJson(json);
}
