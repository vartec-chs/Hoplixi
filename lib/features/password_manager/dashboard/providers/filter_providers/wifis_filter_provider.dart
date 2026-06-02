import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/wifi/wifi_items.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром Wi-Fi
final wifisFilterProvider =
    NotifierProvider.autoDispose<WifisFilterNotifier, WifiFilter>(
      WifisFilterNotifier.new,
    );

class WifisFilterNotifier extends Notifier<WifiFilter> {
  static const String _logTag = 'WifisFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  WifiFilter build() {
    logDebug('Инициализация фильтра Wi-Fi', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return WifiFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(WifiFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр Wi-Fi обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации
  // ============================================================================

  /// Обновить SSID
  void updateSsid(String? ssid) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление SSID: "$ssid"', tag: _logTag);
      state = state.copyWith(ssid: ssid?.trim());
    });
  }

  /// Установить тип защиты
  void setSecurityType(WifiSecurityType? type) {
    logDebug('Установлен тип защиты: $type', tag: _logTag);
    state = state.copyWith(securityType: type);
  }

  /// Установить тип шифрования
  void setEncryption(WifiEncryptionType? encryption) {
    logDebug('Установлен тип шифрования: $encryption', tag: _logTag);
    state = state.copyWith(encryption: encryption);
  }

  /// Фильтр по наличию пароля
  void setHasPassword(bool? value) {
    logDebug('Фильтр "есть пароль" установлен: $value', tag: _logTag);
    state = state.copyWith(hasPassword: value);
  }

  /// Фильтр по скрытости SSID
  void setHiddenSsid(bool? value) {
    logDebug('Фильтр "скрытый SSID" установлен: $value', tag: _logTag);
    state = state.copyWith(hiddenSsid: value);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(WifiSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Обновить весь фильтр сразу
  void updateFilter(WifiFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Сбросить фильтр
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен', tag: _logTag);
    state = WifiFilter(base: ref.read(baseFilterProvider));
  }

  /// Получить копию фильтра с изменениями
  WifiFilter copyFilter({
    BaseFilter? base,
    String? ssid,
    WifiSecurityType? securityType,
    WifiEncryptionType? encryption,
    bool? hasPassword,
    bool? hiddenSsid,
    WifiSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      ssid: ssid ?? state.ssid,
      securityType: securityType ?? state.securityType,
      encryption: encryption ?? state.encryption,
      hasPassword: hasPassword ?? state.hasPassword,
      hiddenSsid: hiddenSsid ?? state.hiddenSsid,
      sortField: sortField ?? state.sortField,
    );
  }
}
