import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'base_filter_provider.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

/// Провайдер для управления фильтром паролей
final passwordsFilterProvider =
    NotifierProvider<PasswordFilterNotifier, PasswordsFilter>(
      PasswordFilterNotifier.new,
    );

class PasswordFilterNotifier extends Notifier<PasswordsFilter> {
  static const String _logTag = 'PasswordFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  PasswordsFilter build() {
    logDebug('Инициализация фильтра паролей', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return PasswordsFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(PasswordsFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр паролей обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации по названию
  // ============================================================================

  /// Обновить фильтр по названию с дебаунсингом
  void updateName(String? name) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление названия: "$name"', tag: _logTag);
      state = state.copyWith(name: name?.trim());
    });
  }

  /// Установить название без дебаунсинга
  void setName(String? name) {
    _debounceTimer?.cancel();
    logDebug('Установка названия: "$name"', tag: _logTag);
    state = state.copyWith(name: name?.trim());
  }

  /// Очистить фильтр названия
  void clearName() {
    _debounceTimer?.cancel();
    logDebug('Очищено название', tag: _logTag);
    state = state.copyWith(name: null);
  }

  // ============================================================================
  // Методы фильтрации по логину
  // ============================================================================

  /// Обновить фильтр по логину с дебаунсингом
  void updateLogin(String? login) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление логина: "$login"', tag: _logTag);
      state = state.copyWith(login: login?.trim());
    });
  }

  /// Установить логин без дебаунсинга
  void setLogin(String? login) {
    _debounceTimer?.cancel();
    logDebug('Установка логина: "$login"', tag: _logTag);
    state = state.copyWith(login: login?.trim());
  }

  /// Очистить фильтр логина
  void clearLogin() {
    _debounceTimer?.cancel();
    logDebug('Очищен логин', tag: _logTag);
    state = state.copyWith(login: null);
  }

  /// Фильтр по наличию логина
  void setHasLogin(bool? hasLogin) {
    logDebug('Фильтр "имеет логин" установлен: $hasLogin', tag: _logTag);
    state = state.copyWith(hasLogin: hasLogin);
  }

  // ============================================================================
  // Методы фильтрации по email
  // ============================================================================

  /// Обновить фильтр по email с дебаунсингом
  void updateEmail(String? email) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление email: "$email"', tag: _logTag);
      state = state.copyWith(email: email?.trim());
    });
  }

  /// Установить email без дебаунсинга
  void setEmail(String? email) {
    _debounceTimer?.cancel();
    logDebug('Установка email: "$email"', tag: _logTag);
    state = state.copyWith(email: email?.trim());
  }

  /// Очистить фильтр email
  void clearEmail() {
    _debounceTimer?.cancel();
    logDebug('Очищен email', tag: _logTag);
    state = state.copyWith(email: null);
  }

  /// Фильтр по наличию email
  void setHasEmail(bool? hasEmail) {
    logDebug('Фильтр "имеет email" установлен: $hasEmail', tag: _logTag);
    state = state.copyWith(hasEmail: hasEmail);
  }

  // ============================================================================
  // Методы фильтрации по URL
  // ============================================================================

  /// Обновить фильтр по URL с дебаунсингом
  void updateUrl(String? url) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление URL: "$url"', tag: _logTag);
      state = state.copyWith(url: url?.trim());
    });
  }

  /// Установить URL без дебаунсинга
  void setUrl(String? url) {
    _debounceTimer?.cancel();
    logDebug('Установка URL: "$url"', tag: _logTag);
    state = state.copyWith(url: url?.trim());
  }

  /// Очистить фильтр URL
  void clearUrl() {
    _debounceTimer?.cancel();
    logDebug('Очищен URL', tag: _logTag);
    state = state.copyWith(url: null);
  }

  /// Фильтр по наличию URL
  void setHasUrl(bool? hasUrl) {
    logDebug('Фильтр "имеет URL" установлен: $hasUrl', tag: _logTag);
    state = state.copyWith(hasUrl: hasUrl);
  }

  // ============================================================================
  // Методы фильтрации по содержимому
  // ============================================================================

  /// Установить фильтр по наличию описания
  void setHasDescription(bool? hasDescription) {
    logDebug(
      'Фильтр "имеет описание" установлен: $hasDescription',
      tag: _logTag,
    );
    state = state.copyWith(hasDescription: hasDescription);
  }

  /// Установить фильтр по наличию заметок
  void setHasNotes(bool? hasNotes) {
    logDebug('Фильтр "имеет заметки" установлен: $hasNotes', tag: _logTag);
    state = state.copyWith(hasNotes: hasNotes);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(PasswordsSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  /// Переключить поле сортировки между несколькими
  void cycleSortField(List<PasswordsSortField> fields) {
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

  /// Проверить есть ли активные фильтры специфичные для паролей
  bool get hasPasswordSpecificConstraints {
    if (state.name != null) return true;
    if (state.login != null) return true;
    if (state.email != null) return true;
    if (state.url != null) return true;
    if (state.hasDescription != null) return true;
    if (state.hasNotes != null) return true;
    if (state.hasUrl != null) return true;
    if (state.hasLogin != null) return true;
    if (state.hasEmail != null) return true;
    return false;
  }

  /// Проверить есть ли активные фильтры (включая базовые)
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Получить текущий фильтр
  PasswordsFilter get currentFilter => state;

  /// Получить базовый фильтр
  BaseFilter get baseFilter => state.base;

  /// Проверить валидность email
  bool get isEmailValid => state.isValidEmail;

  /// Проверить валидность URL
  bool get isUrlValid => state.isValidUrl;

  /// Имеет ли логин или email
  bool get hasLoginOrEmail => state.hasLoginOrEmail;

  /// Обновить весь фильтр паролей сразу
  void updateFilter(PasswordsFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Применить новый фильтр (создать через PasswordsFilter.create)
  void applyFilter(PasswordsFilter newFilter) {
    _debounceTimer?.cancel();
    logDebug('Применен новый фильтр', tag: _logTag);
    state = newFilter;
  }

  /// Сбросить фильтр к начальному состоянию
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен к начальному состоянию', tag: _logTag);
    state = PasswordsFilter(base: ref.read(baseFilterProvider));
  }

  /// Сбросить только фильтры специфичные для паролей
  void clearPasswordSpecificFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры паролей очищены', tag: _logTag);
    state = state.copyWith(
      name: null,
      login: null,
      email: null,
      url: null,
      hasDescription: null,
      hasNotes: null,
      hasUrl: null,
      hasLogin: null,
      hasEmail: null,
    );
  }

  /// Сбросить фильтры по средствам идентификации (login, email)
  void clearIdentificationFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры идентификации очищены', tag: _logTag);
    state = state.copyWith(
      login: null,
      email: null,
      hasLogin: null,
      hasEmail: null,
    );
  }

  /// Сбросить фильтры по местоположению (url, description)
  void clearLocationFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры местоположения очищены', tag: _logTag);
    state = state.copyWith(url: null, hasUrl: null, hasDescription: null);
  }

  /// Фильтр только логины
  void showOnlyWithLogin() {
    logDebug('Показать только с логинами', tag: _logTag);
    state = state.copyWith(hasLogin: true);
  }

  /// Фильтр только email
  void showOnlyWithEmail() {
    logDebug('Показать только с email', tag: _logTag);
    state = state.copyWith(hasEmail: true);
  }

  /// Фильтр только с URL
  void showOnlyWithUrl() {
    logDebug('Показать только с URL', tag: _logTag);
    state = state.copyWith(hasUrl: true);
  }

  /// Фильтр только с описанием
  void showOnlyWithDescription() {
    logDebug('Показать только с описанием', tag: _logTag);
    state = state.copyWith(hasDescription: true);
  }

  /// Применить быстрые фильтры для поиска по идентификации
  void applyIdentificationSearch({
    required String query,
    bool searchLogin = true,
    bool searchEmail = true,
  }) {
    _debounceTimer?.cancel();
    logDebug(
      'Поиск по идентификации: "$query" (login=$searchLogin, email=$searchEmail)',
      tag: _logTag,
    );

    state = state.copyWith(
      login: searchLogin ? query : null,
      email: searchEmail ? query : null,
    );
  }

  /// Получить копию фильтра с изменениями
  PasswordsFilter copyFilter({
    BaseFilter? base,
    String? name,
    String? login,
    String? email,
    String? url,
    bool? hasDescription,
    bool? hasNotes,
    bool? hasUrl,
    bool? hasLogin,
    bool? hasEmail,
    PasswordsSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      name: name ?? state.name,
      login: login ?? state.login,
      email: email ?? state.email,
      url: url ?? state.url,
      hasDescription: hasDescription ?? state.hasDescription,
      hasNotes: hasNotes ?? state.hasNotes,
      hasUrl: hasUrl ?? state.hasUrl,
      hasLogin: hasLogin ?? state.hasLogin,
      hasEmail: hasEmail ?? state.hasEmail,
      sortField: sortField ?? state.sortField,
    );
  }
}
