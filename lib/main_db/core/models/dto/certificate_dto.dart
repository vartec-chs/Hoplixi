import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/certificate/certificate_items.dart';
import '../field_update.dart';
import 'converters.dart';
import 'vault_item_base_dto.dart';

part 'certificate_dto.freezed.dart';
part 'certificate_dto.g.dart';

@freezed
sealed class CertificateDataDto with _$CertificateDataDto {
  const factory CertificateDataDto({
    CertificateFormat? certificateFormat,
    String? certificateFormatOther,
    String? certificatePem,
    @NullableUint8ListBase64Converter() Uint8List? certificateBlob,
    String? privateKey,
    String? privateKeyPassword,
    String? passwordForPfx,
    CertificateKeyAlgorithm? keyAlgorithm,
    String? keyAlgorithmOther,
    int? keySize,
    String? serialNumber,
    String? issuer,
    String? subject,
    DateTime? validFrom,
    DateTime? validTo,
  }) = _CertificateDataDto;

  factory CertificateDataDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateDataDtoFromJson(json);
}

@freezed
sealed class CertificateCardDataDto with _$CertificateCardDataDto {
  const factory CertificateCardDataDto({
    CertificateFormat? certificateFormat,
    CertificateKeyAlgorithm? keyAlgorithm,
    int? keySize,
    String? serialNumber,
    String? issuer,
    String? subject,
    DateTime? validFrom,
    DateTime? validTo,
    @Default(false) bool hasPrivateKey,
    @Default(false) bool hasCertificateBlob,
    @Default(false) bool hasPrivateKeyPassword,
    @Default(false) bool hasPasswordForPfx,
    @Default(false) bool hasCertificatePem,
  }) = _CertificateCardDataDto;

  factory CertificateCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateCardDataDtoFromJson(json);
}

@freezed
sealed class CreateCertificateDto with _$CreateCertificateDto {
  const factory CreateCertificateDto({
    required VaultItemCreateDto item,
    required CertificateDataDto certificate,
  }) = _CreateCertificateDto;

  factory CreateCertificateDto.fromJson(Map<String, dynamic> json) =>
      _$CreateCertificateDtoFromJson(json);
}

@freezed
sealed class CertificateViewDto with _$CertificateViewDto {
  const factory CertificateViewDto({
    required VaultItemViewDto item,
    required CertificateDataDto certificate,
  }) = _CertificateViewDto;

  factory CertificateViewDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateViewDtoFromJson(json);
}

@freezed
sealed class CertificateCardDto with _$CertificateCardDto {
  const factory CertificateCardDto({
    required VaultItemCardDto item,
    required CertificateCardDataDto certificate,
  }) = _CertificateCardDto;

  factory CertificateCardDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateCardDtoFromJson(json);
}

@freezed
sealed class PatchCertificateDataDto with _$PatchCertificateDataDto {
  const factory PatchCertificateDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<CertificateFormat> certificateFormat,
    @Default(FieldUpdate.keep()) FieldUpdate<String> certificateFormatOther,
    @Default(FieldUpdate.keep()) FieldUpdate<String> certificatePem,
    @Default(FieldUpdate.keep()) FieldUpdate<Uint8List> certificateBlob,
    @Default(FieldUpdate.keep()) FieldUpdate<String> privateKey,
    @Default(FieldUpdate.keep()) FieldUpdate<String> privateKeyPassword,
    @Default(FieldUpdate.keep()) FieldUpdate<String> passwordForPfx,
    @Default(FieldUpdate.keep()) FieldUpdate<CertificateKeyAlgorithm> keyAlgorithm,
    @Default(FieldUpdate.keep()) FieldUpdate<String> keyAlgorithmOther,
    @Default(FieldUpdate.keep()) FieldUpdate<int> keySize,
    @Default(FieldUpdate.keep()) FieldUpdate<String> serialNumber,
    @Default(FieldUpdate.keep()) FieldUpdate<String> issuer,
    @Default(FieldUpdate.keep()) FieldUpdate<String> subject,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> validFrom,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> validTo,
  }) = _PatchCertificateDataDto;
}

@freezed
sealed class PatchCertificateDto with _$PatchCertificateDto {
  const factory PatchCertificateDto({
    required VaultItemPatchDto item,
    required PatchCertificateDataDto certificate,
    @Default(FieldUpdate.keep()) FieldUpdate<List<String>> tags,
  }) = _PatchCertificateDto;
}
