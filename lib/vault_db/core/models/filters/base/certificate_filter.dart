import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../tables/certificate/certificate_items.dart';
import 'base_filter.dart';

part 'certificate_filter.freezed.dart';
part 'certificate_filter.g.dart';

enum CertificateSortField {
  name,
  serialNumber,
  issuer,
  subject,
  validFrom,
  validTo,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class CertificateFilter with _$CertificateFilter {
  const factory CertificateFilter({
    @Default(BaseFilter()) BaseFilter base,

    CertificateFormat? certificateFormat,
    CertificateKeyAlgorithm? keyAlgorithm,
    int? keySize,
    String? serialNumber,
    String? issuer,
    String? subject,

    DateTime? validFromAfter,
    DateTime? validToBefore,

    bool? hasPrivateKey,
    bool? hasCertificateBlob,
    bool? hasCertificatePem,

    CertificateSortField? sortField,
  }) = _CertificateFilter;

  factory CertificateFilter.create({
    BaseFilter? base,
    CertificateFormat? certificateFormat,
    CertificateKeyAlgorithm? keyAlgorithm,
    int? keySize,
    String? serialNumber,
    String? issuer,
    String? subject,
    DateTime? validFromAfter,
    DateTime? validToBefore,
    bool? hasPrivateKey,
    bool? hasCertificateBlob,
    bool? hasCertificatePem,
    CertificateSortField? sortField,
  }) {
    final normalizedSerial = serialNumber?.trim();
    final normalizedIssuer = issuer?.trim();
    final normalizedSubject = subject?.trim();

    return CertificateFilter(
      base: base ?? const BaseFilter(),
      certificateFormat: certificateFormat,
      keyAlgorithm: keyAlgorithm,
      keySize: keySize,
      serialNumber: normalizedSerial?.isEmpty == true ? null : normalizedSerial,
      issuer: normalizedIssuer?.isEmpty == true ? null : normalizedIssuer,
      subject: normalizedSubject?.isEmpty == true ? null : normalizedSubject,
      validFromAfter: validFromAfter,
      validToBefore: validToBefore,
      hasPrivateKey: hasPrivateKey,
      hasCertificateBlob: hasCertificateBlob,
      hasCertificatePem: hasCertificatePem,
      sortField: sortField,
    );
  }

  factory CertificateFilter.fromJson(Map<String, dynamic> json) =>
      _$CertificateFilterFromJson(json);
}

extension CertificateFilterHelpers on CertificateFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (certificateFormat != null) return true;
    if (keyAlgorithm != null) return true;
    if (keySize != null) return true;
    if (serialNumber != null) return true;
    if (issuer != null) return true;
    if (subject != null) return true;
    if (validFromAfter != null) return true;
    if (validToBefore != null) return true;
    if (hasPrivateKey != null) return true;
    if (hasCertificateBlob != null) return true;
    if (hasCertificatePem != null) return true;
    return false;
  }
}
