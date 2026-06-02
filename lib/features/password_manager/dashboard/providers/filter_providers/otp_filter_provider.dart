import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/otp/otp_items.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром OTP
final otpsFilterProvider =
    NotifierProvider.autoDispose<OtpFilterNotifier, OtpFilter>(
      OtpFilterNotifier.new,
    );

class OtpFilterNotifier extends Notifier<OtpFilter> {
  static const String _logTag = 'OtpFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  OtpFilter build() {
    logDebug('Инициализация фильтра OTP', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return OtpFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(OtpFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр OTP обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации по типам OTP
  // ============================================================================

  /// Установить тип OTP в фильтре
  void setOtpType(OtpType? type) {
    logDebug('Установлен тип OTP: $type', tag: _logTag);
    state = state.copyWith(type: type);
  }

  /// Показать только TOTP
  void showOnlyTotp() {
    logDebug('Фильтр: только TOTP', tag: _logTag);
    state = state.copyWith(type: OtpType.totp);
  }

  /// Показать только HOTP
  void showOnlyHotp() {
    logDebug('Фильтр: только HOTP', tag: _logTag);
    state = state.copyWith(type: OtpType.hotp);
  }

  /// Очистить фильтр типов
  void clearOtpType() {
    logDebug('Очищен тип OTP', tag: _logTag);
    state = state.copyWith(type: null);
  }

  // ============================================================================
  // Методы фильтрации по алгоритмам
  // ============================================================================

  /// Установить алгоритм в фильтре
  void setAlgorithm(OtpHashAlgorithm? algorithm) {
    logDebug('Установлен алгоритм: $algorithm', tag: _logTag);
    state = state.copyWith(algorithm: algorithm);
  }

  /// Показать только SHA1
  void showOnlySha1() {
    logDebug('Фильтр: только SHA1', tag: _logTag);
    state = state.copyWith(algorithm: OtpHashAlgorithm.SHA1);
  }

  /// Показать только SHA256
  void showOnlySha256() {
    logDebug('Фильтр: только SHA256', tag: _logTag);
    state = state.copyWith(algorithm: OtpHashAlgorithm.SHA256);
  }

  /// Показать только SHA512
  void showOnlySha512() {
    logDebug('Фильтр: только SHA512', tag: _logTag);
    state = state.copyWith(algorithm: OtpHashAlgorithm.SHA512);
  }

  /// Очистить фильтр алгоритмов
  void clearAlgorithm() {
    logDebug('Очищен алгоритм', tag: _logTag);
    state = state.copyWith(algorithm: null);
  }

  // ============================================================================
  // Методы фильтрации по издателю (Issuer)
  // ============================================================================

  /// Обновить фильтр по издателю с дебаунсингом
  void updateIssuer(String? issuer) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление издателя: "$issuer"', tag: _logTag);
      state = state.copyWith(issuer: issuer?.trim());
    });
  }

  /// Установить издателя без дебаунсинга
  void setIssuer(String? issuer) {
    _debounceTimer?.cancel();
    logDebug('Установка издателя: "$issuer"', tag: _logTag);
    state = state.copyWith(issuer: issuer?.trim());
  }

  /// Очистить фильтр издателя
  void clearIssuer() {
    _debounceTimer?.cancel();
    logDebug('Очищен издатель', tag: _logTag);
    state = state.copyWith(issuer: null);
  }

  /// Фильтр по наличию издателя
  void setHasIssuer(bool? hasIssuer) {
    logDebug('Фильтр "имеет издателя" установлен: $hasIssuer', tag: _logTag);
    state = state.copyWith(hasIssuer: hasIssuer);
  }

  // ============================================================================
  // Методы фильтрации по имени аккаунта
  // ============================================================================

  /// Обновить фильтр по имени аккаунта с дебаунсингом
  void updateAccountName(String? accountName) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление имени аккаунта: "$accountName"', tag: _logTag);
      state = state.copyWith(accountName: accountName?.trim());
    });
  }

  /// Установить имя аккаунта без дебаунсинга
  void setAccountName(String? accountName) {
    _debounceTimer?.cancel();
    logDebug('Установка имени аккаунта: "$accountName"', tag: _logTag);
    state = state.copyWith(accountName: accountName?.trim());
  }

  /// Очистить фильтр имени аккаунта
  void clearAccountName() {
    _debounceTimer?.cancel();
    logDebug('Очищено имя аккаунта', tag: _logTag);
    state = state.copyWith(accountName: null);
  }

  /// Фильтр по наличию имени аккаунта
  void setHasAccountName(bool? hasAccountName) {
    logDebug(
      'Фильтр "имеет имя аккаунта" установлен: $hasAccountName',
      tag: _logTag,
    );
    state = state.copyWith(hasAccountName: hasAccountName);
  }

  // ============================================================================
  // Методы фильтрации по цифрам
  // ============================================================================

  /// Установить количество цифр в фильтре
  void setDigits(int? digits) {
    logDebug('Установлено количество цифр: $digits', tag: _logTag);
    state = state.copyWith(digits: digits);
  }

  /// Показать только 6-значные коды
  void showOnly6Digits() {
    logDebug('Фильтр: только 6 цифр', tag: _logTag);
    state = state.copyWith(digits: 6);
  }

  /// Показать только 8-значные коды
  void showOnly8Digits() {
    logDebug('Фильтр: только 8 цифр', tag: _logTag);
    state = state.copyWith(digits: 8);
  }

  /// Очистить фильтр цифр
  void clearDigits() {
    logDebug('Очищены цифры', tag: _logTag);
    state = state.copyWith(digits: null);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(OtpSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  /// Переключить поле сортировки между несколькими
  void cycleSortField(List<OtpSortField> fields) {
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

  /// Проверить есть ли активные фильтры специфичные для OTP
  bool get hasOtpSpecificConstraints => state.hasActiveConstraints;

  /// Проверить есть ли активные фильтры (включая базовые)
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Получить текущий фильтр
  OtpFilter get currentFilter => state;

  /// Получить базовый фильтр
  BaseFilter get baseFilter => state.base;

  /// Обновить весь фильтр OTP сразу
  void updateFilter(OtpFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Применить новый фильтр (создать через OtpFilter.create)
  void applyFilter(OtpFilter newFilter) {
    _debounceTimer?.cancel();
    logDebug('Применен новый фильтр', tag: _logTag);
    state = newFilter;
  }

  /// Сбросить фильтр к начальному состоянию
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен к начальному состоянию', tag: _logTag);
    state = OtpFilter(base: ref.read(baseFilterProvider));
  }

  /// Сбросить только фильтры специфичные для OTP
  void clearOtpSpecificFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры OTP очищены', tag: _logTag);
    state = state.copyWith(
      type: null,
      algorithm: null,
      issuer: null,
      accountName: null,
      digits: null,
      hasIssuer: null,
      hasAccountName: null,
    );
  }

  /// Сбросить фильтры текстовых полей (issuer, accountName)
  void clearTextFilters() {
    _debounceTimer?.cancel();
    logDebug('Текстовые фильтры очищены', tag: _logTag);
    state = state.copyWith(issuer: null, accountName: null);
  }

  /// Применить пресет для TOTP (стандартный: 6 цифр, SHA1)
  void applyTotpPreset() {
    _debounceTimer?.cancel();
    logDebug('Применен пресет TOTP', tag: _logTag);
    state = state.copyWith(
      type: OtpType.totp,
      algorithm: OtpHashAlgorithm.SHA1,
      digits: 6,
    );
  }

  /// Применить пресет для HOTP
  void applyHotpPreset() {
    _debounceTimer?.cancel();
    logDebug('Применен пресет HOTP', tag: _logTag);
    state = state.copyWith(
      type: OtpType.hotp,
      algorithm: OtpHashAlgorithm.SHA1,
      digits: 6,
    );
  }

  /// Получить копию фильтра с изменениями
  OtpFilter copyFilter({
    BaseFilter? base,
    OtpType? type,
    OtpHashAlgorithm? algorithm,
    String? issuer,
    String? accountName,
    int? digits,
    bool? hasIssuer,
    bool? hasAccountName,
    OtpSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      type: type ?? state.type,
      algorithm: algorithm ?? state.algorithm,
      issuer: issuer ?? state.issuer,
      accountName: accountName ?? state.accountName,
      digits: digits ?? state.digits,
      hasIssuer: hasIssuer ?? state.hasIssuer,
      hasAccountName: hasAccountName ?? state.hasAccountName,
      sortField: sortField ?? state.sortField,
    );
  }
}
