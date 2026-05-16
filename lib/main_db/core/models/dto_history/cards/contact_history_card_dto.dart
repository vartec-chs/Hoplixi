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

part 'contact_history_card_dto.freezed.dart';
part 'contact_history_card_dto.g.dart';

@freezed
sealed class ContactHistoryCardDataDto with _$ContactHistoryCardDataDto {
  const factory ContactHistoryCardDataDto({
    String? firstName,
    String? middleName,
    String? lastName,
    String? phone,
    String? email,
    String? company,
    String? jobTitle,
    String? address,
    String? website,
    DateTime? birthday,
    bool? isEmergencyContact,
  }) = _ContactHistoryCardDataDto;

  factory ContactHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$ContactHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class ContactHistoryCardDto with _$ContactHistoryCardDto implements VaultHistoryCardDto {
  const factory ContactHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required ContactHistoryCardDataDto contact,
  }) = _ContactHistoryCardDto;

  factory ContactHistoryCardDto.fromJson(Map<String, dynamic> json) => _$ContactHistoryCardDtoFromJson(json);
}
