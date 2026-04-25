import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_db/core/models/enums/index.dart';
import 'base_filter.dart';

part 'bank_cards_filter.freezed.dart';
part 'bank_cards_filter.g.dart';

enum BankCardsSortField {
  name,
  cardholderName,
  bankName,
  expiryDate,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class BankCardsFilter with _$BankCardsFilter {
  const factory BankCardsFilter({
    required BaseFilter base,
    @Default(<CardType>[]) List<CardType> cardTypes,
    @Default(<CardNetwork>[]) List<CardNetwork> cardNetworks,
    String? bankName,
    String? cardholderName,
    bool? hasExpiryDatePassed,
    bool? isExpiringSoon, // В течение 3 месяцев
    BankCardsSortField? sortField,
  }) = _BankCardsFilter;

  factory BankCardsFilter.create({
    BaseFilter? base,
    List<CardType>? cardTypes,
    List<CardNetwork>? cardNetworks,
    String? bankName,
    String? cardholderName,
    bool? hasExpiryDatePassed,
    bool? isExpiringSoon,
    BankCardsSortField? sortField,
  }) {
    final normalizedBankName = bankName?.trim();
    final normalizedCardholderName = cardholderName?.trim();
    final normalizedCardTypes = (cardTypes ?? <CardType>[]).toSet().toList();
    final normalizedCardNetworks = (cardNetworks ?? <CardNetwork>[])
        .toSet()
        .toList();

    return BankCardsFilter(
      base: base ?? const BaseFilter(),
      cardTypes: normalizedCardTypes,
      cardNetworks: normalizedCardNetworks,
      bankName: normalizedBankName?.isEmpty == true ? null : normalizedBankName,
      cardholderName: normalizedCardholderName?.isEmpty == true
          ? null
          : normalizedCardholderName,
      hasExpiryDatePassed: hasExpiryDatePassed,
      isExpiringSoon: isExpiringSoon,
      sortField: sortField,
    );
  }

  factory BankCardsFilter.fromJson(Map<String, dynamic> json) =>
      _$BankCardsFilterFromJson(json);
}

extension BankCardsFilterHelpers on BankCardsFilter {
  /// Проверяет наличие активных ограничений фильтра
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (cardTypes.isNotEmpty) return true;
    if (cardNetworks.isNotEmpty) return true;
    if (bankName != null) return true;
    if (cardholderName != null) return true;
    if (hasExpiryDatePassed != null) return true;
    if (isExpiringSoon != null) return true;
    return false;
  }
}
