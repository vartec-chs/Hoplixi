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

part 'file_history_card_dto.freezed.dart';
part 'file_history_card_dto.g.dart';

@freezed
sealed class FileHistoryCardDataDto with _$FileHistoryCardDataDto {
  const factory FileHistoryCardDataDto({
    String? fileName,
    String? fileExtension,
    String? mimeType,
    int? fileSize,
    String? sha256,
    FileAvailabilityStatus? availabilityStatus,
    FileIntegrityStatus? integrityStatus,
    DateTime? missingDetectedAt,
    DateTime? deletedAt,
    DateTime? lastIntegrityCheckAt,
    DateTime? snapshotCreatedAt,
    @Default(false) bool hasFilePath,
  }) = _FileHistoryCardDataDto;

  factory FileHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$FileHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class FileHistoryCardDto with _$FileHistoryCardDto implements VaultHistoryCardDto {
  const factory FileHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required FileHistoryCardDataDto file,
  }) = _FileHistoryCardDto;

  factory FileHistoryCardDto.fromJson(Map<String, dynamic> json) => _$FileHistoryCardDtoFromJson(json);
}
