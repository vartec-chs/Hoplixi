import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/api_key/api_key_items.dart';

import 'base_filter_provider.dart';

/// Провайдер для управления фильтром API ключей
final apiKeysFilterProvider =
    NotifierProvider.autoDispose<ApiKeysFilterNotifier, ApiKeyFilter>(
      ApiKeysFilterNotifier.new,
    );

class ApiKeysFilterNotifier extends Notifier<ApiKeyFilter> {
  static const String _logTag = 'ApiKeysFilterNotifier';
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  ApiKeyFilter build() {
    logDebug('Инициализация фильтра API ключей', tag: _logTag);

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('Обновление базового фильтра', tag: _logTag);
      state = state.copyWith(base: next);
    });

    // Очищаем таймер при dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return ApiKeyFilter(base: ref.read(baseFilterProvider));
  }

  void updateFilterDebounced(ApiKeyFilter newFilter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Фильтр API ключей обновлен с дебаунсом', tag: _logTag);
      state = newFilter;
    });
  }

  // ============================================================================
  // Методы фильтрации
  // ============================================================================

  /// Обновить название
  void updateName(String? name) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление названия: "$name"', tag: _logTag);
      state = state.copyWith(name: name?.trim());
    });
  }

  /// Обновить сервис
  void updateService(String? service) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      logDebug('Обновление сервиса: "$service"', tag: _logTag);
      state = state.copyWith(service: service?.trim());
    });
  }

  /// Установить тип токена
  void setTokenType(ApiKeyTokenType? type) {
    logDebug('Установлен тип токена: $type', tag: _logTag);
    state = state.copyWith(tokenType: type);
  }

  /// Установить окружение
  void setEnvironment(ApiKeyEnvironment? env) {
    logDebug('Установлено окружение: $env', tag: _logTag);
    state = state.copyWith(environment: env);
  }

  /// Фильтр по отозванным ключам
  void setRevoked(bool? revoked) {
    logDebug('Фильтр "отозван" установлен: $revoked', tag: _logTag);
    state = state.copyWith(isRevoked: revoked);
  }

  /// Фильтр по наличию срока действия
  void setHasExpiration(bool? hasExpiration) {
    logDebug('Фильтр "есть срок действия" установлен: $hasExpiration', tag: _logTag);
    state = state.copyWith(hasExpiration: hasExpiration);
  }

  // ============================================================================
  // Методы сортировки
  // ============================================================================

  /// Установить поле сортировки
  void setSortField(ApiKeySortField? sortField) {
    logDebug('Поле сортировки установлено: $sortField', tag: _logTag);
    state = state.copyWith(sortField: sortField);
  }

  // ============================================================================
  // Методы управления фильтром в целом
  // ============================================================================

  /// Обновить весь фильтр сразу
  void updateFilter(ApiKeyFilter filter) {
    _debounceTimer?.cancel();
    logDebug('Фильтр обновлен полностью', tag: _logTag);
    state = filter;
  }

  /// Сбросить фильтр
  void reset() {
    _debounceTimer?.cancel();
    logDebug('Фильтр сброшен', tag: _logTag);
    state = ApiKeyFilter(base: ref.read(baseFilterProvider));
  }

  /// Получить копию фильтра с изменениями
  ApiKeyFilter copyFilter({
    BaseFilter? base,
    String? name,
    String? service,
    ApiKeyTokenType? tokenType,
    ApiKeyEnvironment? environment,
    bool? isRevoked,
    bool? hasExpiration,
    ApiKeySortField? sortField,
  }) {
    return state.copyWith(
      base: base ?? state.base,
      name: name ?? state.name,
      service: service ?? state.service,
      tokenType: tokenType ?? state.tokenType,
      environment: environment ?? state.environment,
      isRevoked: isRevoked ?? state.isRevoked,
      hasExpiration: hasExpiration ?? state.hasExpiration,
      sortField: sortField ?? state.sortField,
    );
  }
}
