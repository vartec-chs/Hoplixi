import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/bank_card/bank_card_items.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром банковских карт
final bankCardsFilterProvider =
    NotifierProvider.autoDispose<BankCardsFilterNotifier, BankCardFilter>(
      BankCardsFilterNotifier.new,
    );

class BankCardsFilterNotifier extends Notifier<BankCardFilter> {
  static const String _logTag = 'BankCardsFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  BankCardFilter build() {
    logDebug('Инициализация фильтра банковских карт', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return BankCardFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(BankCardFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр банковских карт обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации по типам карт
  // ============================================================================

  /// Установить тип карты в фильтре
  void setCardType(CardType? type) {
    logDebug('Установлен тип карты: $type', tag: _logTag);
    state = state.copyWith(cardType: type);
  }

  /// Показать только дебетовые карты
  void showOnlyDebitCards() {
    logDebug('Фильтр: только дебетовые карты', tag: _logTag);
    state = state.copyWith(cardType: CardType.debit);
  }

  /// Показать только кредитные карты
  void showOnlyCreditCards() {
    logDebug('Фильтр: только кредитные карты', tag: _logTag);
    state = state.copyWith(cardType: CardType.credit);
  }

  /// Показать только виртуальные карты
  void showOnlyVirtualCards() {
    logDebug('Фильтр: только виртуальные карты', tag: _logTag);
    state = state.copyWith(cardType: CardType.virtual);
  }

  /// Очистить фильтр типов карт
  void clearCardType() {
    logDebug('Очищен тип карты', tag: _logTag);
    state = state.copyWith(cardType: null);
  }

  // ============================================================================
  // Методы фильтрации по платежным сетям
  // ============================================================================

  /// Установить платежную сеть в фильтре
  void setCardNetwork(CardNetwork? network) {
    logDebug('Установлена платежная сеть: $network', tag: _logTag);
    state = state.copyWith(cardNetwork: network);
  }

  /// Показать только Visa
  void showOnlyVisa() {
    logDebug('Фильтр: только Visa', tag: _logTag);
    state = state.copyWith(cardNetwork: CardNetwork.visa);
  }

  /// Показать только Mastercard
  void showOnlyMastercard() {
    logDebug('Фильтр: только Mastercard', tag: _logTag);
    state = state.copyWith(cardNetwork: CardNetwork.mastercard);
  }

  /// Показать только American Express
  void showOnlyAmex() {
    logDebug('Фильтр: только American Express', tag: _logTag);
    state = state.copyWith(cardNetwork: CardNetwork.amex);
  }

  /// Очистить фильтр платежных сетей
  void clearCardNetwork() {
    logDebug('Очищена платежная сеть', tag: _logTag);
    state = state.copyWith(cardNetwork: null);
  }

  // ============================================================================
  // Методы фильтрации по названию банка
  // ============================================================================

  /// Обновить фильтр по названию банка с дебаунсингом
  void updateBankName(String? bankName) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление названия банка: "$bankName"', tag: _logTag);
      state = state.copyWith(bankName: bankName?.trim());
    });
  }

  /// Установить название банка без дебаунсинга
  void setBankName(String? bankName) {
    _debounceTimer?.cancel();
    logDebug('Установка названия банка: "$bankName"', tag: _logTag);
    state = state.copyWith(bankName: bankName?.trim());
  }

  /// Очистить фильтр названия банка
  void clearBankName() {
    _debounceTimer?.cancel();
    logDebug('Очищено название банка', tag: _logTag);
    state = state.copyWith(bankName: null);
  }

  // ============================================================================
  // Методы фильтрации по имени владельца карты
  // ============================================================================

  /// Обновить фильтр по имени владельца с дебаунсингом
  void updateCardholderName(String? cardholderName) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление имени владельца: "$cardholderName"', tag: _logTag);
      state = state.copyWith(cardholderName: cardholderName?.trim());
    });
  }

  /// Установить имя владельца без дебаунсинга
  void setCardholderName(String? cardholderName) {
    _debounceTimer?.cancel();
    logDebug('Установка имени владельца: "$cardholderName"', tag: _logTag);
    state = state.copyWith(cardholderName: cardholderName?.trim());
  }

  /// Очистить фильтр имени владельца
  void clearCardholderName() {
    _debounceTimer?.cancel();
    logDebug('Очищено имя владельца', tag: _logTag);
    state = state.copyWith(cardholderName: null);
  }

  // ============================================================================
  // Методы фильтрации по сроку действия
  // ============================================================================

  /// Фильтр по наличию срока действия
  void setHasExpiry(bool? hasExpiry) {
    logDebug('Фильтр "имеет срок действия" установлен: $hasExpiry', tag: _logTag);
    state = state.copyWith(hasExpiry: hasExpiry);
  }

  /// Установить дату истечения (с)
  void setExpiresAfter(DateTime? date) {
    logDebug('Срок действия от: $date', tag: _logTag);
    state = state.copyWith(expiresAfter: date);
  }

  /// Установить дату истечения (по)
  void setExpiresBefore(DateTime? date) {
    logDebug('Срок действия по: $date', tag: _logTag);
    state = state.copyWith(expiresBefore: date);
  }

  /// Показать только истекшие карты
  void showOnlyExpiredCards() {
    logDebug('Фильтр: только истекшие карты', tag: _logTag);
    state = state.copyWith(expiresBefore: DateTime.now());
  }

  /// Показать только активные карты
  void showOnlyValidCards() {
    logDebug('Фильтр: только активные карты', tag: _logTag);
    state = state.copyWith(expiresAfter: DateTime.now());
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(BankCardSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  /// Сортировать по названию
  void sortByName() {
    logDebug('Сортировка по названию', tag: _logTag);
    state = state.copyWith(sortField: BankCardSortField.name);
  }

  /// Сортировать по имени владельца
  void sortByCardholderName() {
    logDebug('Сортировка по имени владельца', tag: _logTag);
    state = state.copyWith(sortField: BankCardSortField.cardholderName);
  }

  /// Сортировать по названию банка
  void sortByBankName() {
    logDebug('Сортировка по названию банка', tag: _logTag);
    state = state.copyWith(sortField: BankCardSortField.bankName);
  }

  /// Сортировать по дате изменения
  void sortByModifiedAt() {
    logDebug('Сортировка по дате изменения', tag: _logTag);
    state = state.copyWith(sortField: BankCardSortField.modifiedAt);
  }

  /// Переключить поле сортировки между несколькими
  void cycleSortField(List<BankCardSortField> fields) {
    if (fields.isEmpty) return;

    final currentIndex = fields.indexWhere((f) => f == state.sortField);
    final nextIndex = (currentIndex + 1) % fields.length;
    final newField = fields[nextIndex];

    logDebug('Циклический переход: $newField', tag: _logTag);
    state = state.copyWith(sortField: newField);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Проверить есть ли активные фильтры специфичные для карт
  bool get hasBankCardsSpecificConstraints => state.hasActiveConstraints;

  /// Проверить есть ли активные фильтры (включая базовые)
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Получить текущий фильтр
  BankCardFilter get currentFilter => state;

  /// Получить базовый фильтр
  BaseFilter get baseFilter => state.base;

  /// Обновить весь фильтр карт сразу
  void updateFilter(BankCardFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Применить новый фильтр (создать через BankCardFilter.create)
  void applyFilter(BankCardFilter newFilter) {
    _debounceTimer?.cancel();
    logDebug('Применен новый фильтр', tag: _logTag);
    state = newFilter;
  }

  /// Сбросить фильтр к начальному состоянию
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен к начальному состоянию', tag: _logTag);
    state = BankCardFilter(base: ref.read(baseFilterProvider));
  }

  /// Сбросить только фильтры специфичные для карт
  void clearBankCardsSpecificFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры карт очищены', tag: _logTag);
    state = state.copyWith(
      cardType: null,
      cardNetwork: null,
      bankName: null,
      cardholderName: null,
      hasExpiry: null,
      expiresBefore: null,
      expiresAfter: null,
    );
  }

  /// Сбросить фильтры текстовых полей
  void clearTextFilters() {
    _debounceTimer?.cancel();
    logDebug('Текстовые фильтры очищены', tag: _logTag);
    state = state.copyWith(bankName: null, cardholderName: null);
  }

  /// Получить копию фильтра с изменениями
  BankCardFilter copyFilter({
    BaseFilter? base,
    CardType? cardType,
    CardNetwork? cardNetwork,
    String? bankName,
    String? cardholderName,
    bool? hasExpiry,
    DateTime? expiresBefore,
    DateTime? expiresAfter,
    BankCardSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      cardType: cardType ?? state.cardType,
      cardNetwork: cardNetwork ?? state.cardNetwork,
      bankName: bankName ?? state.bankName,
      cardholderName: cardholderName ?? state.cardholderName,
      hasExpiry: hasExpiry ?? state.hasExpiry,
      expiresBefore: expiresBefore ?? state.expiresBefore,
      expiresAfter: expiresAfter ?? state.expiresAfter,
      sortField: sortField ?? state.sortField,
    );
  }
}
