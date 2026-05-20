import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/license_key/license_key_items.dart';
import '../field_update.dart';
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
    @Default([]) List<String> tagIds,
  }) = _CreateLicenseKeyDto;

  factory CreateLicenseKeyDto.fromJson(Map<String, dynamic> json) =>
      _$CreateLicenseKeyDtoFromJson(json);
}

@freezed
sealed class LicenseKeyViewDto
    with _$LicenseKeyViewDto
    implements VaultEntityViewDto {
  const factory LicenseKeyViewDto({
    required VaultItemViewDto item,
    required LicenseKeyDataDto licenseKey,
  }) = _LicenseKeyViewDto;

  factory LicenseKeyViewDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyViewDtoFromJson(json);
}

@freezed
sealed class LicenseKeyCardDto
    with _$LicenseKeyCardDto
    implements VaultEntityCardDto {
  const factory LicenseKeyCardDto({
    required VaultItemCardDto item,
    required LicenseKeyCardDataDto licenseKey,
  }) = _LicenseKeyCardDto;

  factory LicenseKeyCardDto.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyCardDtoFromJson(json);
}

@freezed
sealed class PatchLicenseKeyDataDto with _$PatchLicenseKeyDataDto {
  const factory PatchLicenseKeyDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<String> productName,
    @Default(FieldUpdate.keep()) FieldUpdate<String> vendor,
    @Default(FieldUpdate.keep()) FieldUpdate<String> licenseKey,
    @Default(FieldUpdate.keep()) FieldUpdate<LicenseType> licenseType,
    @Default(FieldUpdate.keep()) FieldUpdate<String> licenseTypeOther,
    @Default(FieldUpdate.keep()) FieldUpdate<String> accountEmail,
    @Default(FieldUpdate.keep()) FieldUpdate<String> accountUsername,
    @Default(FieldUpdate.keep()) FieldUpdate<String> purchaseEmail,
    @Default(FieldUpdate.keep()) FieldUpdate<String> orderNumber,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> purchaseDate,
    @Default(FieldUpdate.keep()) FieldUpdate<double> purchasePrice,
    @Default(FieldUpdate.keep()) FieldUpdate<String> currency,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> validFrom,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> validTo,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> renewalDate,
    @Default(FieldUpdate.keep()) FieldUpdate<int> seats,
    @Default(FieldUpdate.keep()) FieldUpdate<int> activationLimit,
    @Default(FieldUpdate.keep()) FieldUpdate<int> activationsUsed,
  }) = _PatchLicenseKeyDataDto;
}

@freezed
sealed class PatchLicenseKeyDto with _$PatchLicenseKeyDto {
  const factory PatchLicenseKeyDto({
    required VaultItemPatchDto item,
    required PatchLicenseKeyDataDto licenseKey,
    @Default(FieldUpdate.keep()) FieldUpdate<List<String>> tags,
  }) = _PatchLicenseKeyDto;
}
