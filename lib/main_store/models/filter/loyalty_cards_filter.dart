import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'loyalty_cards_filter.freezed.dart';
part 'loyalty_cards_filter.g.dart';

enum LoyaltyCardsSortField {
  name,
  programName,
  holderName,
  tier,
  expiryDate,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class LoyaltyCardsFilter with _$LoyaltyCardsFilter {
  const factory LoyaltyCardsFilter({
    required BaseFilter base,
    String? programName,
    String? holderName,
    String? tier,
    bool? hasBarcode,
    bool? hasExpiryDatePassed,
    bool? isExpiringSoon,
    LoyaltyCardsSortField? sortField,
  }) = _LoyaltyCardsFilter;

  factory LoyaltyCardsFilter.create({
    BaseFilter? base,
    String? programName,
    String? holderName,
    String? tier,
    bool? hasBarcode,
    bool? hasExpiryDatePassed,
    bool? isExpiringSoon,
    LoyaltyCardsSortField? sortField,
  }) {
    final normalizedProgramName = programName?.trim();
    final normalizedHolderName = holderName?.trim();
    final normalizedTier = tier?.trim();

    return LoyaltyCardsFilter(
      base: base ?? const BaseFilter(),
      programName: normalizedProgramName?.isEmpty == true
          ? null
          : normalizedProgramName,
      holderName: normalizedHolderName?.isEmpty == true
          ? null
          : normalizedHolderName,
      tier: normalizedTier?.isEmpty == true ? null : normalizedTier,
      hasBarcode: hasBarcode,
      hasExpiryDatePassed: hasExpiryDatePassed,
      isExpiringSoon: isExpiringSoon,
      sortField: sortField,
    );
  }

  factory LoyaltyCardsFilter.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardsFilterFromJson(json);
}

extension LoyaltyCardsFilterHelpers on LoyaltyCardsFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (programName != null) return true;
    if (holderName != null) return true;
    if (tier != null) return true;
    if (hasBarcode != null) return true;
    if (hasExpiryDatePassed != null) return true;
    if (isExpiringSoon != null) return true;
    if (sortField != null) return true;
    return false;
  }
}
