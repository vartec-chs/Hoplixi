import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/certificate/certificate_items.dart';
import '../dto/converters.dart';
import 'vault_snapshot_base_dto.dart';

part 'certificate_history_dto.freezed.dart';
part 'certificate_history_dto.g.dart';

@freezed
sealed class CertificateHistoryDataDto with _$CertificateHistoryDataDto {
  const factory CertificateHistoryDataDto({
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
  }) = _CertificateHistoryDataDto;

  factory CertificateHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateHistoryDataDtoFromJson(json);
}

@freezed
sealed class CertificateHistoryViewDto with _$CertificateHistoryViewDto {
  const factory CertificateHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required CertificateHistoryDataDto certificate,
  }) = _CertificateHistoryViewDto;

  factory CertificateHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateHistoryViewDtoFromJson(json);
}

@freezed
sealed class CertificateHistoryCardDataDto with _$CertificateHistoryCardDataDto {
  const factory CertificateHistoryCardDataDto({
    CertificateFormat? certificateFormat,
    String? certificateFormatOther,
    CertificateKeyAlgorithm? keyAlgorithm,
    String? keyAlgorithmOther,
    int? keySize,
    String? serialNumber,
    String? issuer,
    String? subject,
    DateTime? validFrom,
    DateTime? validTo,
    required bool hasPem,
    required bool hasBlob,
    required bool hasPrivateKey,
    required bool hasPrivateKeyPassword,
    required bool hasPasswordForPfx,
  }) = _CertificateHistoryCardDataDto;

  factory CertificateHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class CertificateHistoryCardDto with _$CertificateHistoryCardDto {
  const factory CertificateHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required CertificateHistoryCardDataDto certificate,
  }) = _CertificateHistoryCardDto;

  factory CertificateHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateHistoryCardDtoFromJson(json);
}
