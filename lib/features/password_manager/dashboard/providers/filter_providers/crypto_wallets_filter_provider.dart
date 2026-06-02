import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/crypto_wallet/crypto_wallet_items.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром криптокошельков
final cryptoWalletsFilterProvider =
    NotifierProvider.autoDispose<
      CryptoWalletsFilterNotifier,
      CryptoWalletFilter
    >(CryptoWalletsFilterNotifier.new);

class CryptoWalletsFilterNotifier extends Notifier<CryptoWalletFilter> {
  static const String _logTag = 'CryptoWalletsFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  CryptoWalletFilter build() {
    logDebug('Инициализация фильтра криптокошельков', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return CryptoWalletFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(CryptoWalletFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр криптокошельков обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации
  // ============================================================================

  /// Установить тип кошелька
  void setWalletType(CryptoWalletType? type) {
    logDebug('Установлен тип кошелька: $type', tag: _logTag);
    state = state.copyWith(walletType: type);
  }

  /// Установить сеть
  void setNetwork(CryptoNetwork? network) {
    logDebug('Установлена сеть: $network', tag: _logTag);
    state = state.copyWith(network: network);
  }

  /// Обновить аппаратное устройство
  void updateHardwareDevice(String? device) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление аппаратного устройства: "$device"', tag: _logTag);
      state = state.copyWith(hardwareDevice: device?.trim());
    });
  }

  /// Фильтр по наличию мнемоники
  void setHasMnemonic(bool? value) {
    logDebug('Фильтр "есть мнемоника" установлен: $value', tag: _logTag);
    state = state.copyWith(hasMnemonic: value);
  }

  /// Фильтр по наличию приватного ключа
  void setHasPrivateKey(bool? value) {
    logDebug('Фильтр "есть приватный ключ" установлен: $value', tag: _logTag);
    state = state.copyWith(hasPrivateKey: value);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(CryptoWalletSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Обновить весь фильтр сразу
  void updateFilter(CryptoWalletFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Сбросить фильтр
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен', tag: _logTag);
    state = CryptoWalletFilter(base: ref.read(baseFilterProvider));
  }

  /// Получить копию фильтра с изменениями
  CryptoWalletFilter copyFilter({
    BaseFilter? base,
    CryptoWalletType? walletType,
    CryptoNetwork? network,
    String? hardwareDevice,
    bool? hasMnemonic,
    bool? hasPrivateKey,
    CryptoWalletSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      walletType: walletType ?? state.walletType,
      network: network ?? state.network,
      hardwareDevice: hardwareDevice ?? state.hardwareDevice,
      hasMnemonic: hasMnemonic ?? state.hasMnemonic,
      hasPrivateKey: hasPrivateKey ?? state.hasPrivateKey,
      sortField: sortField ?? state.sortField,
    );
  }
}
