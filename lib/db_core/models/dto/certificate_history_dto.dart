import 'package:freezed_annotation/freezed_annotation.dart';

part 'certificate_history_dto.freezed.dart';
part 'certificate_history_dto.g.dart';

@freezed
sealed class CertificateHistoryCardDto with _$CertificateHistoryCardDto {
  const factory CertificateHistoryCardDto({
    required String id,
    required String originalCertificateId,
    required String action,
    required String name,
    String? issuer,
    String? subject,
    String? serialNumber,
    String? fingerprint,
    DateTime? validTo,
    required bool autoRenew,
    required DateTime actionAt,
  }) = _CertificateHistoryCardDto;

  factory CertificateHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateHistoryCardDtoFromJson(json);
}
