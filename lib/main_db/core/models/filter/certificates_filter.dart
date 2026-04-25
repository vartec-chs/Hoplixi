import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'certificates_filter.freezed.dart';
part 'certificates_filter.g.dart';

enum CertificatesSortField {
  name,
  issuer,
  subject,
  validTo,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class CertificatesFilter with _$CertificatesFilter {
  const factory CertificatesFilter({
    required BaseFilter base,
    String? name,
    String? issuer,
    String? subject,
    String? serialNumber,
    String? fingerprint,
    bool? hasPrivateKey,
    bool? hasPfx,
    bool? autoRenew,
    bool? isExpired,
    CertificatesSortField? sortField,
  }) = _CertificatesFilter;

  factory CertificatesFilter.create({
    BaseFilter? base,
    String? name,
    String? issuer,
    String? subject,
    String? serialNumber,
    String? fingerprint,
    bool? hasPrivateKey,
    bool? hasPfx,
    bool? autoRenew,
    bool? isExpired,
    CertificatesSortField? sortField,
  }) {
    String? normalize(String? value) {
      final result = value?.trim();
      if (result == null || result.isEmpty) return null;
      return result;
    }

    return CertificatesFilter(
      base: base ?? const BaseFilter(),
      name: normalize(name),
      issuer: normalize(issuer),
      subject: normalize(subject),
      serialNumber: normalize(serialNumber),
      fingerprint: normalize(fingerprint),
      hasPrivateKey: hasPrivateKey,
      hasPfx: hasPfx,
      autoRenew: autoRenew,
      isExpired: isExpired,
      sortField: sortField,
    );
  }

  factory CertificatesFilter.fromJson(Map<String, dynamic> json) =>
      _$CertificatesFilterFromJson(json);
}

extension CertificatesFilterHelpers on CertificatesFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (issuer != null) return true;
    if (subject != null) return true;
    if (serialNumber != null) return true;
    if (fingerprint != null) return true;
    if (hasPrivateKey != null) return true;
    if (hasPfx != null) return true;
    if (autoRenew != null) return true;
    if (isExpired != null) return true;
    return false;
  }
}
