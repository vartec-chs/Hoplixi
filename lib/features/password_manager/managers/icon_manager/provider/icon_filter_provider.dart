import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/filter/icons_filter.dart';

/// Провайдер для управления состоянием фильтра иконок
final iconFilterProvider = NotifierProvider<IconFilterNotifier, IconsFilter>(
  () {
    return IconFilterNotifier();
  },
);

/// Notifier для управления фильтром иконок
class IconFilterNotifier extends Notifier<IconsFilter> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  IconsFilter build() {
    // Очищаем таймер при destroy провайдера
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const IconsFilter();
  }

  /// Обновить поисковый запрос с дебаунсингом
  void updateQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = state.copyWith(query: query.trim());
    });
  }

  /// Обновить тип иконки
  Future<void> updateType(String? type) async {
    state = state.copyWith(type: type);
    await Future.microtask(() {});
  }

  /// Обновить дату создания (после)
  Future<void> updateCreatedAfter(DateTime? date) async {
    state = state.copyWith(createdAfter: date);
    await Future.microtask(() {});
  }

  /// Обновить дату создания (до)
  Future<void> updateCreatedBefore(DateTime? date) async {
    state = state.copyWith(createdBefore: date);
    await Future.microtask(() {});
  }

  /// Обновить дату изменения (после)
  Future<void> updateModifiedAfter(DateTime? date) async {
    state = state.copyWith(modifiedAfter: date);
    await Future.microtask(() {});
  }

  /// Обновить дату изменения (до)
  Future<void> updateModifiedBefore(DateTime? date) async {
    state = state.copyWith(modifiedBefore: date);
    await Future.microtask(() {});
  }

  /// Обновить поле сортировки
  Future<void> updateSortField(IconsSortField sortField) async {
    state = state.copyWith(sortField: sortField);
    await Future.microtask(() {});
  }

  /// Обновить лимит
  Future<void> updateLimit(int? limit) async {
    state = state.copyWith(limit: limit);
    await Future.microtask(() {});
  }

  /// Обновить offset
  Future<void> updateOffset(int? offset) async {
    state = state.copyWith(offset: offset);
    await Future.microtask(() {});
  }

  /// Сбросить фильтр к начальному состоянию
  Future<void> reset() async {
    _debounceTimer?.cancel();
    state = const IconsFilter();
    await Future.microtask(() {});
  }

  /// Обновить весь фильтр сразу
  Future<void> updateFilter(IconsFilter filter) async {
    _debounceTimer?.cancel();
    state = filter;
    await Future.microtask(() {});
  }
}
