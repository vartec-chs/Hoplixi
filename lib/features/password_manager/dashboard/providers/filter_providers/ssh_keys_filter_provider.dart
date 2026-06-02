import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/ssh_key/ssh_key_items.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром SSH ключей
final sshKeysFilterProvider =
    NotifierProvider.autoDispose<SshKeysFilterNotifier, SshKeyFilter>(
      SshKeysFilterNotifier.new,
    );

class SshKeysFilterNotifier extends Notifier<SshKeyFilter> {
  static const String _logTag = 'SshKeysFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  SshKeyFilter build() {
    logDebug('Инициализация фильтра SSH ключей', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return SshKeyFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(SshKeyFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр SSH ключей обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации
  // ============================================================================

  /// Установить тип ключа
  void setKeyType(SshKeyType? type) {
    logDebug('Установлен тип ключа: $type', tag: _logTag);
    state = state.copyWith(keyType: type);
  }

  /// Фильтр по наличию приватного ключа
  void setHasPrivateKey(bool? value) {
    logDebug('Фильтр "есть приватный ключ" установлен: $value', tag: _logTag);
    state = state.copyWith(hasPrivateKey: value);
  }

  /// Фильтр по наличию публичного ключа
  void setHasPublicKey(bool? value) {
    logDebug('Фильтр "есть публичный ключ" установлен: $value', tag: _logTag);
    state = state.copyWith(hasPublicKey: value);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(SshKeySortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Обновить весь фильтр сразу
  void updateFilter(SshKeyFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Сбросить фильтр
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен', tag: _logTag);
    state = SshKeyFilter(base: ref.read(baseFilterProvider));
  }

  /// Получить копию фильтра с изменениями
  SshKeyFilter copyFilter({
    BaseFilter? base,
    SshKeyType? keyType,
    bool? hasPrivateKey,
    bool? hasPublicKey,
    SshKeySortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      keyType: keyType ?? state.keyType,
      hasPrivateKey: hasPrivateKey ?? state.hasPrivateKey,
      hasPublicKey: hasPublicKey ?? state.hasPublicKey,
      sortField: sortField ?? state.sortField,
    );
  }
}
