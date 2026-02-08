import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'base_filter_provider.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';

/// Провайдер для управления фильтром OTP
final otpsFilterProvider = NotifierProvider<OtpFilterNotifier, OtpsFilter>(
  OtpFilterNotifier.new,
);

class OtpFilterNotifier extends Notifier<OtpsFilter> {
  static const String _logTag = 'OtpFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  OtpsFilter build() {
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

    return OtpsFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(OtpsFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр OTP обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации по типам OTP
  // ============================================================================

  /// Добавить тип OTP в фильтр
  void addOtpType(OtpType type) {
    if (state.types.contains(type)) return;
    final updated = [...state.types, type];
    logDebug('Добавлен тип OTP: $type', tag: _logTag);
    state = state.copyWith(types: updated);
  }

  /// Удалить тип OTP из фильтра
  void removeOtpType(OtpType type) {
    final updated = state.types.where((t) => t != type).toList();
    logDebug('Удален тип OTP: $type', tag: _logTag);
    state = state.copyWith(types: updated);
  }

  /// Переключить тип OTP в фильтре
  void toggleOtpType(OtpType type) {
    if (state.types.contains(type)) {
      removeOtpType(type);
    } else {
      addOtpType(type);
    }
  }

  /// Установить типы OTP (заменить все)
  void setOtpTypes(List<OtpType> types) {
    logDebug('Установлены типы OTP: $types', tag: _logTag);
    state = state.copyWith(types: types);
  }

  /// Показать только TOTP
  void showOnlyTotp() {
    logDebug('Фильтр: только TOTP', tag: _logTag);
    state = state.copyWith(types: [OtpType.totp]);
  }

  /// Показать только HOTP
  void showOnlyHotp() {
    logDebug('Фильтр: только HOTP', tag: _logTag);
    state = state.copyWith(types: [OtpType.hotp]);
  }

  /// Показать все типы OTP
  void showAllOtpTypes() {
    logDebug('Фильтр: все типы OTP', tag: _logTag);
    state = state.copyWith(types: [OtpType.totp, OtpType.hotp]);
  }

  /// Очистить фильтр типов
  void clearOtpTypes() {
    logDebug('Очищены типы OTP', tag: _logTag);
    state = state.copyWith(types: []);
  }

  // ============================================================================
  // Методы фильтрации по алгоритмам
  // ============================================================================

  /// Добавить алгоритм в фильтр
  void addAlgorithm(AlgorithmOtp algorithm) {
    if (state.algorithms.contains(algorithm)) return;
    final updated = [...state.algorithms, algorithm];
    logDebug('Добавлен алгоритм: $algorithm', tag: _logTag);
    state = state.copyWith(algorithms: updated);
  }

  /// Удалить алгоритм из фильтра
  void removeAlgorithm(AlgorithmOtp algorithm) {
    final updated = state.algorithms.where((a) => a != algorithm).toList();
    logDebug('Удален алгоритм: $algorithm', tag: _logTag);
    state = state.copyWith(algorithms: updated);
  }

  /// Переключить алгоритм в фильтре
  void toggleAlgorithm(AlgorithmOtp algorithm) {
    if (state.algorithms.contains(algorithm)) {
      removeAlgorithm(algorithm);
    } else {
      addAlgorithm(algorithm);
    }
  }

  /// Установить алгоритмы (заменить все)
  void setAlgorithms(List<AlgorithmOtp> algorithms) {
    logDebug('Установлены алгоритмы: $algorithms', tag: _logTag);
    state = state.copyWith(algorithms: algorithms);
  }

  /// Показать только SHA1
  void showOnlySha1() {
    logDebug('Фильтр: только SHA1', tag: _logTag);
    state = state.copyWith(algorithms: [AlgorithmOtp.SHA1]);
  }

  /// Показать только SHA256
  void showOnlySha256() {
    logDebug('Фильтр: только SHA256', tag: _logTag);
    state = state.copyWith(algorithms: [AlgorithmOtp.SHA256]);
  }

  /// Показать только SHA512
  void showOnlySha512() {
    logDebug('Фильтр: только SHA512', tag: _logTag);
    state = state.copyWith(algorithms: [AlgorithmOtp.SHA512]);
  }

  /// Показать все алгоритмы
  void showAllAlgorithms() {
    logDebug('Фильтр: все алгоритмы', tag: _logTag);
    state = state.copyWith(
      algorithms: [AlgorithmOtp.SHA1, AlgorithmOtp.SHA256, AlgorithmOtp.SHA512],
    );
  }

  /// Очистить фильтр алгоритмов
  void clearAlgorithms() {
    logDebug('Очищены алгоритмы', tag: _logTag);
    state = state.copyWith(algorithms: []);
  }

  // ============================================================================
  // Методы фильтрации по кодировке секрета
  // ============================================================================

  /// Добавить кодировку в фильтр
  void addSecretEncoding(SecretEncoding encoding) {
    if (state.secretEncodings.contains(encoding)) return;
    final updated = [...state.secretEncodings, encoding];
    logDebug('Добавлена кодировка: $encoding', tag: _logTag);
    state = state.copyWith(secretEncodings: updated);
  }

  /// Удалить кодировку из фильтра
  void removeSecretEncoding(SecretEncoding encoding) {
    final updated = state.secretEncodings.where((e) => e != encoding).toList();
    logDebug('Удалена кодировка: $encoding', tag: _logTag);
    state = state.copyWith(secretEncodings: updated);
  }

  /// Переключить кодировку в фильтре
  void toggleSecretEncoding(SecretEncoding encoding) {
    if (state.secretEncodings.contains(encoding)) {
      removeSecretEncoding(encoding);
    } else {
      addSecretEncoding(encoding);
    }
  }

  /// Установить кодировки (заменить все)
  void setSecretEncodings(List<SecretEncoding> encodings) {
    logDebug('Установлены кодировки: $encodings', tag: _logTag);
    state = state.copyWith(secretEncodings: encodings);
  }

  /// Показать только BASE32
  void showOnlyBase32() {
    logDebug('Фильтр: только BASE32', tag: _logTag);
    state = state.copyWith(secretEncodings: [SecretEncoding.BASE32]);
  }

  /// Показать только HEX
  void showOnlyHex() {
    logDebug('Фильтр: только HEX', tag: _logTag);
    state = state.copyWith(secretEncodings: [SecretEncoding.HEX]);
  }

  /// Показать только BINARY
  void showOnlyBinary() {
    logDebug('Фильтр: только BINARY', tag: _logTag);
    state = state.copyWith(secretEncodings: [SecretEncoding.BINARY]);
  }

  /// Показать все кодировки
  void showAllSecretEncodings() {
    logDebug('Фильтр: все кодировки', tag: _logTag);
    state = state.copyWith(
      secretEncodings: [
        SecretEncoding.BASE32,
        SecretEncoding.HEX,
        SecretEncoding.BINARY,
      ],
    );
  }

  /// Очистить фильтр кодировок
  void clearSecretEncodings() {
    logDebug('Очищены кодировки', tag: _logTag);
    state = state.copyWith(secretEncodings: []);
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

  // ============================================================================
  // Методы фильтрации по цифрам
  // ============================================================================

  /// Добавить количество цифр в фильтр
  void addDigit(int digit) {
    if (state.digits.contains(digit)) return;
    if (digit != 6 && digit != 8) {
      logDebug('Неверное количество цифр: $digit', tag: _logTag);
      return;
    }
    final updated = [...state.digits, digit];
    logDebug('Добавлено количество цифр: $digit', tag: _logTag);
    state = state.copyWith(digits: updated);
  }

  /// Удалить количество цифр из фильтра
  void removeDigit(int digit) {
    final updated = state.digits.where((d) => d != digit).toList();
    logDebug('Удалено количество цифр: $digit', tag: _logTag);
    state = state.copyWith(digits: updated);
  }

  /// Переключить количество цифр
  void toggleDigit(int digit) {
    if (state.digits.contains(digit)) {
      removeDigit(digit);
    } else {
      addDigit(digit);
    }
  }

  /// Установить цифры (заменить все)
  void setDigits(List<int> digits) {
    logDebug('Установлены цифры: $digits', tag: _logTag);
    state = state.copyWith(digits: digits);
  }

  /// Показать только 6-значные коды
  void showOnly6Digits() {
    logDebug('Фильтр: только 6 цифр', tag: _logTag);
    state = state.copyWith(digits: [6]);
  }

  /// Показать только 8-значные коды
  void showOnly8Digits() {
    logDebug('Фильтр: только 8 цифр', tag: _logTag);
    state = state.copyWith(digits: [8]);
  }

  /// Показать оба варианта
  void showBothDigits() {
    logDebug('Фильтр: 6 и 8 цифр', tag: _logTag);
    state = state.copyWith(digits: [6, 8]);
  }

  /// Очистить фильтр цифр
  void clearDigits() {
    logDebug('Очищены цифры', tag: _logTag);
    state = state.copyWith(digits: []);
  }

  // ============================================================================
  // Методы фильтрации по периодам
  // ============================================================================

  /// Добавить период в фильтр
  void addPeriod(int period) {
    if (state.periods.contains(period)) return;
    if (period <= 0 || period > 300) {
      logDebug('Неверный период: $period', tag: _logTag);
      return;
    }
    final updated = [...state.periods, period];
    logDebug('Добавлен период: $period', tag: _logTag);
    state = state.copyWith(periods: updated);
  }

  /// Удалить период из фильтра
  void removePeriod(int period) {
    final updated = state.periods.where((p) => p != period).toList();
    logDebug('Удален период: $period', tag: _logTag);
    state = state.copyWith(periods: updated);
  }

  /// Переключить период
  void togglePeriod(int period) {
    if (state.periods.contains(period)) {
      removePeriod(period);
    } else {
      addPeriod(period);
    }
  }

  /// Установить периоды (заменить все)
  void setPeriods(List<int> periods) {
    logDebug('Установлены периоды: $periods', tag: _logTag);
    state = state.copyWith(periods: periods);
  }

  /// Показать только 30 секунд (стандартный)
  void showOnly30SecondPeriod() {
    logDebug('Фильтр: только 30 секунд', tag: _logTag);
    state = state.copyWith(periods: [30]);
  }

  /// Показать только 60 секунд
  void showOnly60SecondPeriod() {
    logDebug('Фильтр: только 60 секунд', tag: _logTag);
    state = state.copyWith(periods: [60]);
  }

  /// Очистить фильтр периодов
  void clearPeriods() {
    logDebug('Очищены периоды', tag: _logTag);
    state = state.copyWith(periods: []);
  }

  // ============================================================================
  // Методы фильтрации по статусу
  // ============================================================================

  /// Установить фильтр по наличию связанного пароля
  void setHasPasswordLink(bool? hasPasswordLink) {
    logDebug(
      'Фильтр "имеет связь с паролем" установлен: $hasPasswordLink',
      tag: _logTag,
    );
    state = state.copyWith(hasPasswordLink: hasPasswordLink);
  }

  /// Показать только с связанными паролями
  void showOnlyWithPasswordLink() {
    logDebug('Фильтр: только с связанными паролями', tag: _logTag);
    state = state.copyWith(hasPasswordLink: true);
  }

  /// Показать только без связанных паролей
  void showOnlyWithoutPasswordLink() {
    logDebug('Фильтр: только без связанных паролей', tag: _logTag);
    state = state.copyWith(hasPasswordLink: false);
  }

  /// Установить фильтр по наличию заметок
  void setHasNotes(bool? hasNotes) {
    logDebug('Фильтр "имеет заметки" установлен: $hasNotes', tag: _logTag);
    state = state.copyWith(hasNotes: hasNotes);
  }

  /// Показать только с заметками
  void showOnlyWithNotes() {
    logDebug('Фильтр: только с заметками', tag: _logTag);
    state = state.copyWith(hasNotes: true);
  }

  /// Показать только без заметок
  void showOnlyWithoutNotes() {
    logDebug('Фильтр: только без заметок', tag: _logTag);
    state = state.copyWith(hasNotes: false);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(OtpsSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  /// Переключить поле сортировки между несколькими
  void cycleSortField(List<OtpsSortField> fields) {
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
  bool get hasOtpSpecificConstraints {
    if (state.types.isNotEmpty) return true;
    if (state.algorithms.isNotEmpty) return true;
    if (state.issuer != null) return true;
    if (state.accountName != null) return true;
    if (state.digits.isNotEmpty) return true;
    if (state.periods.isNotEmpty) return true;
    if (state.secretEncodings.isNotEmpty) return true;
    if (state.hasPasswordLink != null) return true;
    if (state.hasNotes != null) return true;
    return false;
  }

  /// Проверить есть ли активные фильтры (включая базовые)
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Получить текущий фильтр
  OtpsFilter get currentFilter => state;

  /// Получить базовый фильтр
  BaseFilter get baseFilter => state.base;

  /// Это TOTP-only фильтр?
  bool get isTotpOnly => state.isTotpOnly;

  /// Это HOTP-only фильтр?
  bool get isHotpOnly => state.isHotpOnly;

  /// Проверить валидность периода
  bool get isValidPeriod => state.isValidPeriod;

  /// Проверить валидность цифр
  bool get isValidDigits => state.isValidDigits;

  /// Обновить весь фильтр OTP сразу
  void updateFilter(OtpsFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Применить новый фильтр (создать через OtpsFilter.create)
  void applyFilter(OtpsFilter newFilter) {
    _debounceTimer?.cancel();
    logDebug('Применен новый фильтр', tag: _logTag);
    state = newFilter;
  }

  /// Сбросить фильтр к начальному состоянию
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен к начальному состоянию', tag: _logTag);
    state = OtpsFilter(base: ref.read(baseFilterProvider));
  }

  /// Сбросить только фильтры специфичные для OTP
  void clearOtpSpecificFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры OTP очищены', tag: _logTag);
    state = state.copyWith(
      types: [],
      algorithms: [],
      issuer: null,
      accountName: null,
      digits: [],
      periods: [],
      secretEncodings: [],
      hasPasswordLink: null,
      hasNotes: null,
    );
  }

  /// Сбросить фильтры текстовых полей (issuer, accountName)
  void clearTextFilters() {
    _debounceTimer?.cancel();
    logDebug('Текстовые фильтры очищены', tag: _logTag);
    state = state.copyWith(issuer: null, accountName: null);
  }

  /// Сбросить фильтры по конфигурации (digits, periods, encodings)
  void clearConfigurationFilters() {
    _debounceTimer?.cancel();
    logDebug('Фильтры конфигурации очищены', tag: _logTag);
    state = state.copyWith(digits: [], periods: [], secretEncodings: []);
  }

  /// Применить пресет для TOTP (стандартный: 6 цифр, 30 секунд, BASE32, SHA1)
  void applyTotpPreset() {
    _debounceTimer?.cancel();
    logDebug('Применен пресет TOTP', tag: _logTag);
    state = state.copyWith(
      types: [OtpType.totp],
      algorithms: [AlgorithmOtp.SHA1],
      digits: [6],
      periods: [30],
      secretEncodings: [SecretEncoding.BASE32],
    );
  }

  /// Применить пресет для HOTP
  void applyHotpPreset() {
    _debounceTimer?.cancel();
    logDebug('Применен пресет HOTP', tag: _logTag);
    state = state.copyWith(
      types: [OtpType.hotp],
      algorithms: [AlgorithmOtp.SHA1],
      digits: [6],
      secretEncodings: [SecretEncoding.BASE32],
      periods: [],
    );
  }

  /// Получить копию фильтра с изменениями
  OtpsFilter copyFilter({
    BaseFilter? base,
    List<OtpType>? types,
    List<AlgorithmOtp>? algorithms,
    String? issuer,
    String? accountName,
    List<int>? digits,
    List<int>? periods,
    List<SecretEncoding>? secretEncodings,
    bool? hasPasswordLink,
    bool? hasNotes,
    OtpsSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      types: types ?? state.types,
      algorithms: algorithms ?? state.algorithms,
      issuer: issuer ?? state.issuer,
      accountName: accountName ?? state.accountName,
      digits: digits ?? state.digits,
      periods: periods ?? state.periods,
      secretEncodings: secretEncodings ?? state.secretEncodings,
      hasPasswordLink: hasPasswordLink ?? state.hasPasswordLink,
      hasNotes: hasNotes ?? state.hasNotes,
      sortField: sortField ?? state.sortField,
    );
  }
}
