import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'license_keys_filter.freezed.dart';
part 'license_keys_filter.g.dart';

enum LicenseKeysSortField {
  name,
  product,
  licenseType,
  orderId,
  expiresAt,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class LicenseKeysFilter with _$LicenseKeysFilter {
  const factory LicenseKeysFilter({
    required BaseFilter base,
    String? name,
    String? product,
    String? licenseType,
    String? orderId,
    String? purchaseFrom,
    String? supportContact,
    bool? expiredOnly,
    LicenseKeysSortField? sortField,
  }) = _LicenseKeysFilter;

  factory LicenseKeysFilter.create({
    BaseFilter? base,
    String? name,
    String? product,
    String? licenseType,
    String? orderId,
    String? purchaseFrom,
    String? supportContact,
    bool? expiredOnly,
    LicenseKeysSortField? sortField,
  }) {
    String? normalize(String? value) {
      final result = value?.trim();
      if (result == null || result.isEmpty) return null;
      return result;
    }

    return LicenseKeysFilter(
      base: base ?? const BaseFilter(),
      name: normalize(name),
      product: normalize(product),
      licenseType: normalize(licenseType),
      orderId: normalize(orderId),
      purchaseFrom: normalize(purchaseFrom),
      supportContact: normalize(supportContact),
      expiredOnly: expiredOnly,
      sortField: sortField,
    );
  }

  factory LicenseKeysFilter.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeysFilterFromJson(json);
}

extension LicenseKeysFilterHelpers on LicenseKeysFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (product != null) return true;
    if (licenseType != null) return true;
    if (orderId != null) return true;
    if (purchaseFrom != null) return true;
    if (supportContact != null) return true;
    if (expiredOnly != null) return true;
    return false;
  }
}
