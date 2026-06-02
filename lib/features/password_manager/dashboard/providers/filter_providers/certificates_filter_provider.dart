import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/certificate/certificate_items.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром сертификатов
final certificatesFilterProvider =
    NotifierProvider.autoDispose<CertificatesFilterNotifier, CertificateFilter>(
      CertificatesFilterNotifier.new,
    );

class CertificatesFilterNotifier extends Notifier<CertificateFilter> {
  static const String _logTag = 'CertificatesFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  CertificateFilter build() {
    logDebug('Инициализация фильтра сертификатов', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return CertificateFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(CertificateFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр сертификатов обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации
  // ============================================================================

  /// Обновить издателя
  void updateIssuer(String? issuer) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление издателя: "$issuer"', tag: _logTag);
      state = state.copyWith(issuer: issuer?.trim());
    });
  }

  /// Обновить субъекта
  void updateSubject(String? subject) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление субъекта: "$subject"', tag: _logTag);
      state = state.copyWith(subject: subject?.trim());
    });
  }

  /// Обновить серийный номер
  void updateSerialNumber(String? serial) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление сер. номера: "$serial"', tag: _logTag);
      state = state.copyWith(serialNumber: serial?.trim());
    });
  }

  /// Установить формат сертификата
  void setCertificateFormat(CertificateFormat? format) {
    logDebug('Установлен формат: $format', tag: _logTag);
    state = state.copyWith(certificateFormat: format);
  }

  /// Установить алгоритм ключа
  void setKeyAlgorithm(CertificateKeyAlgorithm? algo) {
    logDebug('Установлен алгоритм: $algo', tag: _logTag);
    state = state.copyWith(keyAlgorithm: algo);
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
  void setSortField(CertificateSortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Обновить весь фильтр сразу
  void updateFilter(CertificateFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Сбросить фильтр
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен', tag: _logTag);
    state = CertificateFilter(base: ref.read(baseFilterProvider));
  }

  /// Получить копию фильтра с изменениями
  CertificateFilter copyFilter({
    BaseFilter? base,
    String? issuer,
    String? subject,
    String? serialNumber,
    CertificateFormat? certificateFormat,
    CertificateKeyAlgorithm? keyAlgorithm,
    bool? hasPrivateKey,
    CertificateSortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      issuer: issuer ?? state.issuer,
      subject: subject ?? state.subject,
      serialNumber: serialNumber ?? state.serialNumber,
      certificateFormat: certificateFormat ?? state.certificateFormat,
      keyAlgorithm: keyAlgorithm ?? state.keyAlgorithm,
      hasPrivateKey: hasPrivateKey ?? state.hasPrivateKey,
      sortField: sortField ?? state.sortField,
    );
  }
}
