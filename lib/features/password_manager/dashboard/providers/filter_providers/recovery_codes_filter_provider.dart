import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром кодов восстановления
final recoveryCodesFilterProvider =
    NotifierProvider.autoDispose<
      RecoveryCodesFilterNotifier,
      RecoveryCodesFilter
    >(RecoveryCodesFilterNotifier.new);

class RecoveryCodesFilterNotifier extends Notifier<RecoveryCodesFilter> {
  static const String _logTag = 'RecoveryCodesFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  RecoveryCodesFilter build() {
    logDebug('Инициализация фильтра кодов восстановления', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return RecoveryCodesFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(RecoveryCodesFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр кодов обновления обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации
  // ============================================================================

  /// Фильтр по одноразовости
  void setOneTime(bool? value) {
    logDebug('Фильтр "одноразовые" установлен: $value', tag: _logTag);
    state = state.copyWith(oneTime: value);
  }

  /// Фильтр по наличию кодов
  void setHasCodes(bool? value) {
    logDebug('Фильтр "есть коды" установлен: $value', tag: _logTag);
    state = state.copyWith(hasCodes: value);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(RecoveryCodesSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Обновить весь фильтр сразу
  void updateFilter(RecoveryCodesFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Сбросить фильтр
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен', tag: _logTag);
    state = RecoveryCodesFilter(base: ref.read(baseFilterProvider));
  }

  /// Получить копию фильтра с изменениями
  RecoveryCodesFilter copyFilter({
    BaseFilter? base,
    bool? oneTime,
    bool? hasCodes,
    DateTime? generatedAfter,
    DateTime? generatedBefore,
    RecoveryCodesSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      oneTime: oneTime ?? state.oneTime,
      hasCodes: hasCodes ?? state.hasCodes,
      generatedAfter: generatedAfter ?? state.generatedAfter,
      generatedBefore: generatedBefore ?? state.generatedBefore,
      sortField: sortField ?? state.sortField,
    );
  }
}
