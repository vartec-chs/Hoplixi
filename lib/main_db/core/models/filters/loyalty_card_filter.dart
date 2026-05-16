import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/loyalty_card/loyalty_card_items.dart';
import 'base_filter.dart';

part 'loyalty_card_filter.freezed.dart';
part 'loyalty_card_filter.g.dart';

enum LoyaltyCardSortField {
  name,
  programName,
  issuer,
  validTo,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class LoyaltyCardFilter with _$LoyaltyCardFilter {
  const factory LoyaltyCardFilter({
    @Default(BaseFilter()) BaseFilter base,

    String? programName,
    LoyaltyBarcodeType? barcodeType,
    String? issuer,
    String? website,
    String? phone,
    String? email,

    DateTime? validFromAfter,
    DateTime? validToBefore,

    bool? hasCardNumber,
    bool? hasBarcodeValue,
    bool? hasPassword,

    LoyaltyCardSortField? sortField,
  }) = _LoyaltyCardFilter;

  factory LoyaltyCardFilter.create({
    BaseFilter? base,
    String? programName,
    LoyaltyBarcodeType? barcodeType,
    String? issuer,
    String? website,
    String? phone,
    String? email,
    DateTime? validFromAfter,
    DateTime? validToBefore,
    bool? hasCardNumber,
    bool? hasBarcodeValue,
    bool? hasPassword,
    LoyaltyCardSortField? sortField,
  }) {
    final normalizedProgram = programName?.trim();
    final normalizedIssuer = issuer?.trim();
    final normalizedWebsite = website?.trim();
    final normalizedPhone = phone?.trim();
    final normalizedEmail = email?.trim();

    return LoyaltyCardFilter(
      base: base ?? const BaseFilter(),
      programName: normalizedProgram?.isEmpty == true ? null : normalizedProgram,
      barcodeType: barcodeType,
      issuer: normalizedIssuer?.isEmpty == true ? null : normalizedIssuer,
      website: normalizedWebsite?.isEmpty == true ? null : normalizedWebsite,
      phone: normalizedPhone?.isEmpty == true ? null : normalizedPhone,
      email: normalizedEmail?.isEmpty == true ? null : normalizedEmail,
      validFromAfter: validFromAfter,
      validToBefore: validToBefore,
      hasCardNumber: hasCardNumber,
      hasBarcodeValue: hasBarcodeValue,
      hasPassword: hasPassword,
      sortField: sortField,
    );
  }

  factory LoyaltyCardFilter.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardFilterFromJson(json);
}

extension LoyaltyCardFilterHelpers on LoyaltyCardFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (programName != null) return true;
    if (barcodeType != null) return true;
    if (issuer != null) return true;
    if (website != null) return true;
    if (phone != null) return true;
    if (email != null) return true;
    if (validFromAfter != null || validToBefore != null) return true;
    if (hasCardNumber != null) return true;
    if (hasBarcodeValue != null) return true;
    if (hasPassword != null) return true;
    return false;
  }
}
