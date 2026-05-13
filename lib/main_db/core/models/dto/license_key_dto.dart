import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/license_key/license_key_items.dart';
import 'vault_item_base_dto.dart';

part 'license_key_dto.freezed.dart';
part 'license_key_dto.g.dart';

@freezed
sealed class LicenseKeyDataDto with _$LicenseKeyDataDto {
  const factory LicenseKeyDataDto({
    required String productName,
    String? vendor,
    required String licenseKey,
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
  }) = _LicenseKeyDataDto;

  factory LicenseKeyDataDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyDataDtoFromJson(json);
}

@freezed
sealed class LicenseKeyCardDataDto with _$LicenseKeyCardDataDto {
  const factory LicenseKeyCardDataDto({
    required String productName,
    String? vendor,
    LicenseType? licenseType,
    String? accountEmail,
    String? accountUsername,
    DateTime? validTo,
    @Default(true) bool hasKey,
  }) = _LicenseKeyCardDataDto;

  factory LicenseKeyCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyCardDataDtoFromJson(json);
}

@freezed
sealed class CreateLicenseKeyDto with _$CreateLicenseKeyDto {
  const factory CreateLicenseKeyDto({
    required VaultItemCreateDto item,
    required LicenseKeyDataDto licenseKey,
  }) = _CreateLicenseKeyDto;

  factory CreateLicenseKeyDto.fromJson(Map<String, dynamic> json) =>
      _$CreateLicenseKeyDtoFromJson(json);
}

@freezed
sealed class UpdateLicenseKeyDto with _$UpdateLicenseKeyDto {
  const factory UpdateLicenseKeyDto({
    required VaultItemUpdateDto item,
    required LicenseKeyDataDto licenseKey,
  }) = _UpdateLicenseKeyDto;

  factory UpdateLicenseKeyDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateLicenseKeyDtoFromJson(json);
}

@freezed
sealed class LicenseKeyViewDto with _$LicenseKeyViewDto {
  const factory LicenseKeyViewDto({
    required VaultItemViewDto item,
    required LicenseKeyDataDto licenseKey,
  }) = _LicenseKeyViewDto;

  factory LicenseKeyViewDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyViewDtoFromJson(json);
}

@freezed
sealed class LicenseKeyCardDto with _$LicenseKeyCardDto {
  const factory LicenseKeyCardDto({
    required VaultItemCardDto item,
    required LicenseKeyCardDataDto licenseKey,
  }) = _LicenseKeyCardDto;

  factory LicenseKeyCardDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyCardDtoFromJson(json);
}
