import '../../../tables/certificate/certificate_items.dart';
import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'certificate_history_card_dto.freezed.dart';
part 'certificate_history_card_dto.g.dart';

@freezed
sealed class CertificateHistoryCardDataDto with _$CertificateHistoryCardDataDto {
  const factory CertificateHistoryCardDataDto({
    CertificateFormat? certificateFormat,
    CertificateKeyAlgorithm? keyAlgorithm,
    int? keySize,
    String? serialNumber,
    String? issuer,
    String? subject,
    DateTime? validFrom,
    DateTime? validTo,
    @Default(false) bool hasCertificatePem,
    @Default(false) bool hasCertificateBlob,
    @Default(false) bool hasPrivateKey,
    @Default(false) bool hasPrivateKeyPassword,
    @Default(false) bool hasPasswordForPfx,
  }) = _CertificateHistoryCardDataDto;

  factory CertificateHistoryCardDataDto.fromJson(Map<String, dynamic> json) => _$CertificateHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class CertificateHistoryCardDto with _$CertificateHistoryCardDto implements VaultHistoryCardDto {
  const factory CertificateHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required CertificateHistoryCardDataDto certificate,
  }) = _CertificateHistoryCardDto;

  factory CertificateHistoryCardDto.fromJson(Map<String, dynamic> json) => _$CertificateHistoryCardDtoFromJson(json);
}