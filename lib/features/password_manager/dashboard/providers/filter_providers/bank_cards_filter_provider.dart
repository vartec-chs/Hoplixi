import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'base_filter_provider.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

/// Провайдер для управления фильтром банковских карт
final bankCardsFilterProvider =
    NotifierProvider<BankCardsFilterNotifier, BankCardsFilter>(
      BankCardsFilterNotifier.new,
    );

class BankCardsFilterNotifier extends Notifier<BankCardsFilter> {
  static const String _logTag = 'BankCardsFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  BankCardsFilter build() {
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

    return BankCardsFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(BankCardsFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации по типам карт
  // ============================================================================

  /// Добавить тип карты в фильтр
  void addCardType(CardType type) {
    if (state.cardTypes.contains(type)) return;
    final updated = [...state.cardTypes, type];
    logDebug('Добавлен тип карты: $type', tag: _logTag);
    state = state.copyWith(cardTypes: updated);
  }

  /// Удалить тип карты из фильтра
  void removeCardType(CardType type) {
    final updated = state.cardTypes.where((t) => t != type).toList();
    logDebug('Удален тип карты: $type', tag: _logTag);
    state = state.copyWith(cardTypes: updated);
  }

  /// Переключить тип карты в фильтре
  void toggleCardType(CardType type) {
    if (state.cardTypes.contains(type)) {
      removeCardType(type);
    } else {
      addCardType(type);
    }
  }

  /// Установить типы карт (заменить все)
  void setCardTypes(List<CardType> types) {
    logDebug('Установлены типы карт: $types', tag: _logTag);
    state = state.copyWith(cardTypes: types);
  }

  /// Показать только дебетовые карты
  void showOnlyDebitCards() {
    logDebug('Фильтр: только дебетовые карты', tag: _logTag);
    state = state.copyWith(cardTypes: [CardType.debit]);
  }

  /// Показать только кредитные карты
  void showOnlyCreditCards() {
    logDebug('Фильтр: только кредитные карты', tag: _logTag);
    state = state.copyWith(cardTypes: [CardType.credit]);
  }

  /// Показать только виртуальные карты
  void showOnlyVirtualCards() {
    logDebug('Фильтр: только виртуальные карты', tag: _logTag);
    state = state.copyWith(cardTypes: [CardType.virtual]);
  }

  /// Показать все типы карт
  void showAllCardTypes() {
    logDebug('Фильтр: все типы карт', tag: _logTag);
    state = state.copyWith(
      cardTypes: [
        CardType.debit,
        CardType.credit,
        CardType.prepaid,
        CardType.virtual,
      ],
    );
  }

  /// Очистить фильтр типов карт
  void clearCardTypes() {
    logDebug('Очищены типы карт', tag: _logTag);
    state = state.copyWith(cardTypes: []);
  }

  // ============================================================================
  // Методы фильтрации по платежным сетям
  // ============================================================================

  /// Добавить платежную сеть в фильтр
  void addCardNetwork(CardNetwork network) {
    if (state.cardNetworks.contains(network)) return;
    final updated = [...state.cardNetworks, network];
    logDebug('Добавлена платежная сеть: $network', tag: _logTag);
    state = state.copyWith(cardNetworks: updated);
  }

  /// Удалить платежную сеть из фильтра
  void removeCardNetwork(CardNetwork network) {
    final updated = state.cardNetworks.where((n) => n != network).toList();
    logDebug('Удалена платежная сеть: $network', tag: _logTag);
    state = state.copyWith(cardNetworks: updated);
  }

  /// Переключить платежную сеть в фильтре
  void toggleCardNetwork(CardNetwork network) {
    if (state.cardNetworks.contains(network)) {
      removeCardNetwork(network);
    } else {
      addCardNetwork(network);
    }
  }

  /// Установить платежные сети (заменить все)
  void setCardNetworks(List<CardNetwork> networks) {
    logDebug('Установлены платежные сети: $networks', tag: _logTag);
    state = state.copyWith(cardNetworks: networks);
  }

  /// Показать только Visa
  void showOnlyVisa() {
    logDebug('Фильтр: только Visa', tag: _logTag);
    state = state.copyWith(cardNetworks: [CardNetwork.visa]);
  }

  /// Показать только Mastercard
  void showOnlyMastercard() {
    logDebug('Фильтр: только Mastercard', tag: _logTag);
    state = state.copyWith(cardNetworks: [CardNetwork.mastercard]);
  }

  /// Показать только American Express
  void showOnlyAmex() {
    logDebug('Фильтр: только American Express', tag: _logTag);
    state = state.copyWith(cardNetworks: [CardNetwork.amex]);
  }

  /// Показать основные сети (Visa, Mastercard, Amex)
  void showMajorNetworks() {
    logDebug('Фильтр: основные сети', tag: _logTag);
    state = state.copyWith(
      cardNetworks: [
        CardNetwork.visa,
        CardNetwork.mastercard,
        CardNetwork.amex,
      ],
    );
  }

  /// Показать все платежные сети
  void showAllCardNetworks() {
    logDebug('Фильтр: все платежные сети', tag: _logTag);
    state = state.copyWith(
      cardNetworks: [
        CardNetwork.visa,
        CardNetwork.mastercard,
        CardNetwork.amex,
        CardNetwork.discover,
        CardNetwork.dinersclub,
        CardNetwork.jcb,
        CardNetwork.unionpay,
        CardNetwork.other,
      ],
    );
  }

  /// Очистить фильтр платежных сетей
  void clearCardNetworks() {
    logDebug('Очищены платежные сети', tag: _logTag);
    state = state.copyWith(cardNetworks: []);
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

  /// Установить фильтр по истекшим датам
  void setHasExpiryDatePassed(bool? hasExpiryDatePassed) {
    logDebug(
      'Фильтр "срок истек" установлен: $hasExpiryDatePassed',
      tag: _logTag,
    );
    state = state.copyWith(hasExpiryDatePassed: hasExpiryDatePassed);
  }

  /// Показать только истекшие карты
  void showOnlyExpiredCards() {
    logDebug('Фильтр: только истекшие карты', tag: _logTag);
    state = state.copyWith(hasExpiryDatePassed: true);
  }

  /// Показать только активные карты
  void showOnlyValidCards() {
    logDebug('Фильтр: только активные карты', tag: _logTag);
    state = state.copyWith(hasExpiryDatePassed: false);
  }

  /// Установить фильтр по карточкам, истекающим скоро (в течение 3 месяцев)
  void setIsExpiringSoon(bool? isExpiringSoon) {
    logDebug(
      'Фильтр "истекает скоро" установлен: $isExpiringSoon',
      tag: _logTag,
    );
    state = state.copyWith(isExpiringSoon: isExpiringSoon);
  }

  /// Показать только карты, истекающие скоро
  void showOnlyExpiringCardssoon() {
    logDebug('Фильтр: только карты, истекающие скоро', tag: _logTag);
    state = state.copyWith(isExpiringSoon: true);
  }

  /// Показать только карты с далеким сроком действия
  void showOnlyCardsWithLongValidity() {
    logDebug('Фильтр: карты с далеким сроком действия', tag: _logTag);
    state = state.copyWith(isExpiringSoon: false);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(BankCardsSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  /// Сортировать по названию
  void sortByName() {
    logDebug('Сортировка по названию', tag: _logTag);
    state = state.copyWith(sortField: BankCardsSortField.name);
  }

  /// Сортировать по имени владельца
  void sortByCardholderName() {
    logDebug('Сортировка по имени владельца', tag: _logTag);
    state = state.copyWith(sortField: BankCardsSortField.cardholderName);
  }

  /// Сортировать по названию банка
  void sortByBankName() {
    logDebug('Сортировка по названию банка', tag: _logTag);
    state = state.copyWith(sortField: BankCardsSortField.bankName);
  }

  /// Сортировать по дате истечения
  void sortByExpiryDate() {
    logDebug('Сортировка по дате истечения', tag: _logTag);
    state = state.copyWith(sortField: BankCardsSortField.expiryDate);
  }

  /// Сортировать по дате создания
  void sortByCreatedAt() {
    logDebug('Сортировка по дате создания', tag: _logTag);
    state = state.copyWith(sortField: BankCardsSortField.createdAt);
  }

  /// Сортировать по дате изменения
  void sortByModifiedAt() {
    logDebug('Сортировка по дате изменения', tag: _logTag);
    state = state.copyWith(sortField: BankCardsSortField.modifiedAt);
  }

  /// Переключить поле сортировки между несколькими
  void cycleSortField(List<BankCardsSortField> fields) {
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
  bool get hasBankCardsSpecificConstraints {
    if (state.cardTypes.isNotEmpty) return true;
    if (state.cardNetworks.isNotEmpty) return true;
    if (state.bankName != null) return true;
    if (state.cardholderName != null) return true;
    if (state.hasExpiryDatePassed != null) return true;
    if (state.isExpiringSoon != null) return true;
    return false;
  }

  /// Проверить есть ли активные фильтры (включая базовые)
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Получить текущий фильтр
  BankCardsFilter get currentFilter => state;

  /// Получить базовый фильтр
  BaseFilter get baseFilter => state.base;

  /// Обновить весь фильтр карт сразу
  void updateFilter(BankCardsFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Применить новый фильтр (создать через BankCardsFilter.create)
  void applyFilter(BankCardsFilter newFilter) {
    _debounceTimer?.cancel();
    logDebug('Применен новый фильтр', tag: _logTag);
    state = newFilter;
  }

  /// Сбросить фильтр к начальному состоянию
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен к начальному состоянию', tag: _logTag);
    state = BankCardsFilter(base: ref.read(baseFilterProvider));
  }

  /// Сбросить только фильтры специфичные для карт
  void clearBankCardsSpecificFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры карт очищены', tag: _logTag);
    state = state.copyWith(
      cardTypes: [],
      cardNetworks: [],
      bankName: null,
      cardholderName: null,
      hasExpiryDatePassed: null,
      isExpiringSoon: null,
    );
  }

  /// Сбросить фильтры текстовых полей
  void clearTextFilters() {
    _debounceTimer?.cancel();
    logDebug('Текстовые фильтры очищены', tag: _logTag);
    state = state.copyWith(bankName: null, cardholderName: null);
  }

  /// Применить пресет для поиска проблемных карт (истекшие или истекающие)
  void applyProblematicCardsPreset() {
    _debounceTimer?.cancel();
    logDebug('Применен пресет для проблемных карт', tag: _logTag);
    state = state.copyWith(hasExpiryDatePassed: true, isExpiringSoon: true);
  }

  /// Применить пресет для поиска активных карт
  void applyActiveCardsPreset() {
    _debounceTimer?.cancel();
    logDebug('Применен пресет для активных карт', tag: _logTag);
    state = state.copyWith(hasExpiryDatePassed: false, isExpiringSoon: false);
  }

  /// Получить копию фильтра с изменениями
  BankCardsFilter copyFilter({
    BaseFilter? base,
    List<CardType>? cardTypes,
    List<CardNetwork>? cardNetworks,
    String? bankName,
    String? cardholderName,
    bool? hasExpiryDatePassed,
    bool? isExpiringSoon,
    BankCardsSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      cardTypes: cardTypes ?? state.cardTypes,
      cardNetworks: cardNetworks ?? state.cardNetworks,
      bankName: bankName ?? state.bankName,
      cardholderName: cardholderName ?? state.cardholderName,
      hasExpiryDatePassed: hasExpiryDatePassed ?? state.hasExpiryDatePassed,
      isExpiringSoon: isExpiringSoon ?? state.isExpiringSoon,
      sortField: sortField ?? state.sortField,
    );
  }
}
