import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром контактов
final contactsFilterProvider =
    NotifierProvider.autoDispose<ContactsFilterNotifier, ContactFilter>(
      ContactsFilterNotifier.new,
    );

class ContactsFilterNotifier extends Notifier<ContactFilter> {
  static const String _logTag = 'ContactsFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  ContactFilter build() {
    logDebug('Инициализация фильтра контактов', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return ContactFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(ContactFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр контактов обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации
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

  /// Обновить телефон
  void updatePhone(String? phone) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление телефона: "$phone"', tag: _logTag);
      state = state.copyWith(phone: phone?.trim());
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

  /// Обновить компанию
  void updateCompany(String? company) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление компании: "$company"', tag: _logTag);
      state = state.copyWith(company: company?.trim());
    });
  }

  /// Фильтр по экстренному контакту
  void setIsEmergencyContact(bool? value) {
    logDebug('Фильтр "экстренный контакт" установлен: $value', tag: _logTag);
    state = state.copyWith(isEmergencyContact: value);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(ContactSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Обновить весь фильтр сразу
  void updateFilter(ContactFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Сбросить фильтр
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен', tag: _logTag);
    state = ContactFilter(base: ref.read(baseFilterProvider));
  }

  /// Получить копию фильтра с изменениями
  ContactFilter copyFilter({
    BaseFilter? base,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? company,
    bool? isEmergencyContact,
    ContactSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      firstName: firstName ?? state.firstName,
      lastName: lastName ?? state.lastName,
      phone: phone ?? state.phone,
      email: email ?? state.email,
      company: company ?? state.company,
      isEmergencyContact: isEmergencyContact ?? state.isEmergencyContact,
      sortField: sortField ?? state.sortField,
    );
  }
}
