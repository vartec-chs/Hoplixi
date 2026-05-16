import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/license_key/license_key_items.dart';
import 'base_filter.dart';

part 'license_key_filter.freezed.dart';
part 'license_key_filter.g.dart';

enum LicenseKeySortField {
  name,
  productName,
  vendor,
  licenseType,
  purchaseDate,
  validTo,
  renewalDate,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class LicenseKeyFilter with _$LicenseKeyFilter {
  const factory LicenseKeyFilter({
    @Default(BaseFilter()) BaseFilter base,

    String? productName,
    String? vendor,
    LicenseType? licenseType,
    String? accountEmail,
    String? accountUsername,
    String? purchaseEmail,
    String? orderNumber,

    DateTime? purchaseDateAfter,
    DateTime? purchaseDateBefore,

    DateTime? validFromAfter,
    DateTime? validToBefore,

    DateTime? renewalDateBefore,

    bool? hasExpiration,
    bool? hasRenewal,

    LicenseKeySortField? sortField,
  }) = _LicenseKeyFilter;

  factory LicenseKeyFilter.create({
    BaseFilter? base,
    String? productName,
    String? vendor,
    LicenseType? licenseType,
    String? accountEmail,
    String? accountUsername,
    String? purchaseEmail,
    String? orderNumber,
    DateTime? purchaseDateAfter,
    DateTime? purchaseDateBefore,
    DateTime? validFromAfter,
    DateTime? validToBefore,
    DateTime? renewalDateBefore,
    bool? hasExpiration,
    bool? hasRenewal,
    LicenseKeySortField? sortField,
  }) {
    final normalizedProduct = productName?.trim();
    final normalizedVendor = vendor?.trim();
    final normalizedAccountEmail = accountEmail?.trim();
    final normalizedAccountUser = accountUsername?.trim();
    final normalizedPurchaseEmail = purchaseEmail?.trim();
    final normalizedOrder = orderNumber?.trim();

    return LicenseKeyFilter(
      base: base ?? const BaseFilter(),
      productName: normalizedProduct?.isEmpty == true ? null : normalizedProduct,
      vendor: normalizedVendor?.isEmpty == true ? null : normalizedVendor,
      licenseType: licenseType,
      accountEmail: normalizedAccountEmail?.isEmpty == true ? null : normalizedAccountEmail,
      accountUsername: normalizedAccountUser?.isEmpty == true ? null : normalizedAccountUser,
      purchaseEmail: normalizedPurchaseEmail?.isEmpty == true ? null : normalizedPurchaseEmail,
      orderNumber: normalizedOrder?.isEmpty == true ? null : normalizedOrder,
      purchaseDateAfter: purchaseDateAfter,
      purchaseDateBefore: purchaseDateBefore,
      validFromAfter: validFromAfter,
      validToBefore: validToBefore,
      renewalDateBefore: renewalDateBefore,
      hasExpiration: hasExpiration,
      hasRenewal: hasRenewal,
      sortField: sortField,
    );
  }

  factory LicenseKeyFilter.fromJson(Map<String, dynamic> json) =>
      _$LicenseKeyFilterFromJson(json);
}

extension LicenseKeyFilterHelpers on LicenseKeyFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (productName != null) return true;
    if (vendor != null) return true;
    if (licenseType != null) return true;
    if (accountEmail != null) return true;
    if (accountUsername != null) return true;
    if (purchaseEmail != null) return true;
    if (orderNumber != null) return true;
    if (purchaseDateAfter != null || purchaseDateBefore != null) return true;
    if (validFromAfter != null || validToBefore != null) return true;
    if (renewalDateBefore != null) return true;
    if (hasExpiration != null) return true;
    if (hasRenewal != null) return true;
    return false;
  }
}
