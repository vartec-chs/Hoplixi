import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/license_key/license_key_items.dart';
import 'vault_snapshot_base_dto.dart';

part 'license_key_history_dto.freezed.dart';
part 'license_key_history_dto.g.dart';

@freezed
sealed class LicenseKeyHistoryDataDto with _$LicenseKeyHistoryDataDto {
  const factory LicenseKeyHistoryDataDto({
    required String productName,
    String? vendor,
    String? licenseKey,
    LicenseType? licenseType,
    String? licenseTypeOther,
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
  }) = _LicenseKeyHistoryDataDto;

  factory LicenseKeyHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyHistoryDataDtoFromJson(json);
}

@freezed
sealed class LicenseKeyHistoryViewDto with _$LicenseKeyHistoryViewDto {
  const factory LicenseKeyHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required LicenseKeyHistoryDataDto licenseKey,
  }) = _LicenseKeyHistoryViewDto;

  factory LicenseKeyHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyHistoryViewDtoFromJson(json);
}

@freezed
sealed class LicenseKeyHistoryCardDataDto with _$LicenseKeyHistoryCardDataDto {
  const factory LicenseKeyHistoryCardDataDto({
    required String productName,
    String? vendor,
    LicenseType? licenseType,
    String? licenseTypeOther,
    String? accountEmail,
    String? accountUsername,
    DateTime? purchaseDate,
    DateTime? validTo,
    DateTime? renewalDate,
    int? seats,
    int? activationsUsed,
    required bool hasLicenseKey,
  }) = _LicenseKeyHistoryCardDataDto;

  factory LicenseKeyHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class LicenseKeyHistoryCardDto with _$LicenseKeyHistoryCardDto {
  const factory LicenseKeyHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required LicenseKeyHistoryCardDataDto licenseKey,
  }) = _LicenseKeyHistoryCardDto;

  factory LicenseKeyHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyHistoryCardDtoFromJson(json);
}
