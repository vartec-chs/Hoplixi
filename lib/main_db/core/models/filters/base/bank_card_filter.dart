import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../tables/bank_card/bank_card_items.dart';
import 'base_filter.dart';

part 'bank_card_filter.freezed.dart';
part 'bank_card_filter.g.dart';

enum BankCardSortField {
  name,
  cardholderName,
  bankName,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class BankCardFilter with _$BankCardFilter {
  const factory BankCardFilter({
    @Default(BaseFilter()) BaseFilter base,

    String? cardholderName,
    CardType? cardType,
    CardNetwork? cardNetwork,
    String? bankName,

    bool? hasExpiry,
    DateTime? expiresBefore,
    DateTime? expiresAfter,

    bool? hasCvv,
    bool? hasAccountNumber,

    BankCardSortField? sortField,
  }) = _BankCardFilter;

  factory BankCardFilter.create({
    BaseFilter? base,
    String? cardholderName,
    CardType? cardType,
    CardNetwork? cardNetwork,
    String? bankName,
    bool? hasExpiry,
    DateTime? expiresBefore,
    DateTime? expiresAfter,
    bool? hasCvv,
    bool? hasAccountNumber,
    BankCardSortField? sortField,
  }) {
    final normalizedCardholder = cardholderName?.trim();
    final normalizedBankName = bankName?.trim();

    return BankCardFilter(
      base: base ?? const BaseFilter(),
      cardholderName: normalizedCardholder?.isEmpty == true
          ? null
          : normalizedCardholder,
      cardType: cardType,
      cardNetwork: cardNetwork,
      bankName: normalizedBankName?.isEmpty == true ? null : normalizedBankName,
      hasExpiry: hasExpiry,
      expiresBefore: expiresBefore,
      expiresAfter: expiresAfter,
      hasCvv: hasCvv,
      hasAccountNumber: hasAccountNumber,
      sortField: sortField,
    );
  }

  factory BankCardFilter.fromJson(Map<String, dynamic> json) =>
      _$BankCardFilterFromJson(json);
}

extension BankCardFilterHelpers on BankCardFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (cardholderName != null) return true;
    if (cardType != null) return true;
    if (cardNetwork != null) return true;
    if (bankName != null) return true;
    if (hasExpiry != null) return true;
    if (expiresBefore != null || expiresAfter != null) return true;
    if (hasCvv != null) return true;
    if (hasAccountNumber != null) return true;
    return false;
  }
}
