import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';

/// Провайдер для управления состоянием фильтра категорий
final categoryPickerFilterProvider =
    NotifierProvider.autoDispose<CategoryFilterNotifier, CategoriesFilter>(
      CategoryFilterNotifier.new,
    );

/// Notifier для управления фильтром категорий
class CategoryFilterNotifier extends Notifier<CategoriesFilter> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  CategoriesFilter build() {
    // Очищаем таймер при destroy провайдера
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const CategoriesFilter();
  }

  /// Обновить поисковый запрос с дебаунсингом
  void updateQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = state.copyWith(query: query.trim());
    });
  }

  /// Обновить тип категории
  Future<void> updateType(String? type) async {
    state = state.copyWith(type: type);
  }

  /// Обновить цвет
  Future<void> updateColor(String? color) async {
    state = state.copyWith(color: color);
  }

  /// Обновить фильтр по наличию иконки
  Future<void> updateHasIcon(bool? hasIcon) async {
    state = state.copyWith(hasIcon: hasIcon);
  }

  /// Обновить фильтр по наличию описания
  Future<void> updateHasDescription(bool? hasDescription) async {
    state = state.copyWith(hasDescription: hasDescription);
  }

  /// Обновить дату создания (после)
  Future<void> updateCreatedAfter(DateTime? date) async {
    state = state.copyWith(createdAfter: date);
  }

  /// Обновить дату создания (до)
  Future<void> updateCreatedBefore(DateTime? date) async {
    state = state.copyWith(createdBefore: date);
  }

  /// Обновить дату изменения (после)
  Future<void> updateModifiedAfter(DateTime? date) async {
    state = state.copyWith(modifiedAfter: date);
  }

  /// Обновить дату изменения (до)
  Future<void> updateModifiedBefore(DateTime? date) async {
    state = state.copyWith(modifiedBefore: date);
  }

  /// Обновить поле сортировки
  Future<void> updateSortField(CategoriesSortField sortField) async {
    state = state.copyWith(sortField: sortField);
  }

  /// Сбросить фильтр к начальному состоянию
  Future<void> reset() async {
    _debounceTimer?.cancel();
    state = const CategoriesFilter();
  }

  /// Обновить весь фильтр сразу
  Future<void> updateFilter(CategoriesFilter filter) async {
    _debounceTimer?.cancel();
    state = filter;
  }
}
