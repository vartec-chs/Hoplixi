import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/loyalty_card/loyalty_card_items.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром карт лояльности
final loyaltyCardsFilterProvider =
    NotifierProvider.autoDispose<LoyaltyCardsFilterNotifier, LoyaltyCardFilter>(
      LoyaltyCardsFilterNotifier.new,
    );

class LoyaltyCardsFilterNotifier extends Notifier<LoyaltyCardFilter> {
  static const String _logTag = 'LoyaltyCardsFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  LoyaltyCardFilter build() {
    logDebug('Инициализация фильтра карт лояльности', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return LoyaltyCardFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(LoyaltyCardFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр карт лояльности обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации
  // ============================================================================

  /// Обновить название программы
  void updateProgramName(String? name) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление программы: "$name"', tag: _logTag);
      state = state.copyWith(programName: name?.trim());
    });
  }

  /// Обновить эмитента
  void updateIssuer(String? issuer) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление эмитента: "$issuer"', tag: _logTag);
      state = state.copyWith(issuer: issuer?.trim());
    });
  }

  /// Установить тип штрихкода
  void setBarcodeType(LoyaltyBarcodeType? type) {
    logDebug('Установлен тип штрихкода: $type', tag: _logTag);
    state = state.copyWith(barcodeType: type);
  }

  /// Фильтр по наличию номера карты
  void setHasCardNumber(bool? value) {
    logDebug('Фильтр "есть номер карты" установлен: $value', tag: _logTag);
    state = state.copyWith(hasCardNumber: value);
  }

  /// Фильтр по наличию штрихкода
  void setHasBarcodeValue(bool? value) {
    logDebug('Фильтр "есть штрихкод" установлен: $value', tag: _logTag);
    state = state.copyWith(hasBarcodeValue: value);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(LoyaltyCardSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Обновить весь фильтр сразу
  void updateFilter(LoyaltyCardFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Сбросить фильтр
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен', tag: _logTag);
    state = LoyaltyCardFilter(base: ref.read(baseFilterProvider));
  }

  /// Получить копию фильтра с изменениями
  LoyaltyCardFilter copyFilter({
    BaseFilter? base,
    String? programName,
    String? issuer,
    LoyaltyBarcodeType? barcodeType,
    bool? hasCardNumber,
    bool? hasBarcodeValue,
    LoyaltyCardSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      programName: programName ?? state.programName,
      issuer: issuer ?? state.issuer,
      barcodeType: barcodeType ?? state.barcodeType,
      hasCardNumber: hasCardNumber ?? state.hasCardNumber,
      hasBarcodeValue: hasBarcodeValue ?? state.hasBarcodeValue,
      sortField: sortField ?? state.sortField,
    );
  }
}
