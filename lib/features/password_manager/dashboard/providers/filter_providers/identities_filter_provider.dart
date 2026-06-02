import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром личностей
final identitiesFilterProvider =
    NotifierProvider.autoDispose<IdentitiesFilterNotifier, IdentityFilter>(
      IdentitiesFilterNotifier.new,
    );

class IdentitiesFilterNotifier extends Notifier<IdentityFilter> {
  static const String _logTag = 'IdentitiesFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  IdentityFilter build() {
    logDebug('Инициализация фильтра личностей', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return IdentityFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(IdentityFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр личностей обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации по текстовым полям
  // ============================================================================

  /// Обновить имя
  void updateFirstName(String? firstName) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление имени: "$firstName"', tag: _logTag);
      state = state.copyWith(firstName: firstName?.trim());
    });
  }

  /// Обновить фамилию
  void updateLastName(String? lastName) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление фамилии: "$lastName"', tag: _logTag);
      state = state.copyWith(lastName: lastName?.trim());
    });
  }

  /// Обновить отображаемое имя
  void updateDisplayName(String? displayName) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление отбр. имени: "$displayName"', tag: _logTag);
      state = state.copyWith(displayName: displayName?.trim());
    });
  }

  /// Обновить имя пользователя
  void updateUsername(String? username) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление username: "$username"', tag: _logTag);
      state = state.copyWith(username: username?.trim());
    });
  }

  /// Обновить email
  void updateEmail(String? email) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление email: "$email"', tag: _logTag);
      state = state.copyWith(email: email?.trim());
    });
  }

  // ============================================================================
  // Статусные фильтры
  // ============================================================================

  /// Фильтр по наличию паспорта
  void setHasPassportNumber(bool? value) {
    logDebug('Фильтр "есть паспорт" установлен: $value', tag: _logTag);
    state = state.copyWith(hasPassportNumber: value);
  }

  /// Фильтр по наличию ИНН
  void setHasTaxId(bool? value) {
    logDebug('Фильтр "есть ИНН" установлен: $value', tag: _logTag);
    state = state.copyWith(hasTaxId: value);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(IdentitySortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Обновить весь фильтр сразу
  void updateFilter(IdentityFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Сбросить фильтр
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен', tag: _logTag);
    state = IdentityFilter(base: ref.read(baseFilterProvider));
  }

  /// Получить копию фильтра с изменениями
  IdentityFilter copyFilter({
    BaseFilter? base,
    String? firstName,
    String? lastName,
    String? displayName,
    String? username,
    String? email,
    bool? hasPassportNumber,
    bool? hasTaxId,
    IdentitySortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      firstName: firstName ?? state.firstName,
      lastName: lastName ?? state.lastName,
      displayName: displayName ?? state.displayName,
      username: username ?? state.username,
      email: email ?? state.email,
      hasPassportNumber: hasPassportNumber ?? state.hasPassportNumber,
      hasTaxId: hasTaxId ?? state.hasTaxId,
      sortField: sortField ?? state.sortField,
    );
  }
}
