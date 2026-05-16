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

part 'api_key_history_card_dto.freezed.dart';
part 'api_key_history_card_dto.g.dart';

@freezed
sealed class ApiKeyHistoryCardDataDto with _$ApiKeyHistoryCardDataDto {
  const factory ApiKeyHistoryCardDataDto({
    String? service,
    ApiKeyTokenType? tokenType,
    ApiKeyEnvironment? environment,
    DateTime? expiresAt,
    DateTime? revokedAt,
    int? rotationPeriodDays,
    DateTime? lastRotatedAt,
    String? owner,
    String? baseUrl,
    @Default(false) bool hasKey,
  }) = _ApiKeyHistoryCardDataDto;

  factory ApiKeyHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$ApiKeyHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class ApiKeyHistoryCardDto with _$ApiKeyHistoryCardDto implements VaultHistoryCardDto {
  const factory ApiKeyHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required ApiKeyHistoryCardDataDto apikey,
  }) = _ApiKeyHistoryCardDto;

  factory ApiKeyHistoryCardDto.fromJson(Map<String, dynamic> json) => _$ApiKeyHistoryCardDtoFromJson(json);
}
