import '../../../tables/license_key/license_key_items.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'license_key_history_card_dto.freezed.dart';
part 'license_key_history_card_dto.g.dart';

@freezed
sealed class LicenseKeyHistoryCardDataDto with _$LicenseKeyHistoryCardDataDto {
  const factory LicenseKeyHistoryCardDataDto({
    String? productName,
    String? vendor,
    LicenseType? licenseType,
    String? accountEmail,
    String? accountUsername,
    String? purchaseEmail,
    String? orderNumber,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? currency,
    DateTime? validFrom,
    DateTime? validTo,
    DateTime? renewalDate,
    int? seats,
    int? activationLimit,
    int? activationsUsed,
    @Default(false) bool hasLicenseKey,
  }) = _LicenseKeyHistoryCardDataDto;

  factory LicenseKeyHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class LicenseKeyHistoryCardDto
    with _$LicenseKeyHistoryCardDto
    implements VaultHistoryCardDto {
  const factory LicenseKeyHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required LicenseKeyHistoryCardDataDto licensekey,
  }) = _LicenseKeyHistoryCardDto;

  factory LicenseKeyHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyHistoryCardDtoFromJson(json);
}
