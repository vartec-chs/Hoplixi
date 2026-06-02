import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/license_key/license_key_items.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром лицензий
final licenseKeysFilterProvider =
    NotifierProvider.autoDispose<LicenseKeysFilterNotifier, LicenseKeyFilter>(
      LicenseKeysFilterNotifier.new,
    );

class LicenseKeysFilterNotifier extends Notifier<LicenseKeyFilter> {
  static const String _logTag = 'LicenseKeysFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  LicenseKeyFilter build() {
    logDebug('Инициализация фильтра лицензий', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return LicenseKeyFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(LicenseKeyFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр лицензий обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации
  // ============================================================================

  /// Обновить название продукта
  void updateProductName(String? name) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление продукта: "$name"', tag: _logTag);
      state = state.copyWith(productName: name?.trim());
    });
  }

  /// Обновить поставщика
  void updateVendor(String? vendor) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление поставщика: "$vendor"', tag: _logTag);
      state = state.copyWith(vendor: vendor?.trim());
    });
  }

  /// Установить тип лицензии
  void setLicenseType(LicenseType? type) {
    logDebug('Установлен тип лицензии: $type', tag: _logTag);
    state = state.copyWith(licenseType: type);
  }

  /// Фильтр по наличию срока действия
  void setHasExpiration(bool? value) {
    logDebug('Фильтр "есть срок действия" установлен: $value', tag: _logTag);
    state = state.copyWith(hasExpiration: value);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(LicenseKeySortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Обновить весь фильтр сразу
  void updateFilter(LicenseKeyFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Сбросить фильтр
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен', tag: _logTag);
    state = LicenseKeyFilter(base: ref.read(baseFilterProvider));
  }

  /// Получить копию фильтра с изменениями
  LicenseKeyFilter copyFilter({
    BaseFilter? base,
    String? productName,
    String? vendor,
    LicenseType? licenseType,
    bool? hasExpiration,
    LicenseKeySortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      productName: productName ?? state.productName,
      vendor: vendor ?? state.vendor,
      licenseType: licenseType ?? state.licenseType,
      hasExpiration: hasExpiration ?? state.hasExpiration,
      sortField: sortField ?? state.sortField,
    );
  }
}
