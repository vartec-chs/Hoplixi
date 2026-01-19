import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';

/// Провайдер для управления состоянием фильтра категорий
final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, CategoriesFilter>(
      () => CategoryFilterNotifier(),
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

    return CategoriesFilter.create(
      sortField: CategoriesSortField.name,
      limit: 30,
    );
  }

  /// Обновить поисковый запрос с дебаунсингом
  void updateQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = state.copyWith(query: query.trim());
    });
  }

  /// Обновить тип категории
  Future<void> updateType(List<CategoryType?> types) async {
    state = state.copyWith(types: types);
    await Future.microtask(() {});
  }

  /// Обновить цвет
  Future<void> updateColor(String? color) async {
    state = state.copyWith(color: color);
    await Future.microtask(() {});
  }

  /// Обновить фильтр наличия иконки
  Future<void> updateHasIcon(bool? hasIcon) async {
    state = state.copyWith(hasIcon: hasIcon);
    await Future.microtask(() {});
  }

  /// Обновить фильтр наличия описания
  Future<void> updateHasDescription(bool? hasDescription) async {
    state = state.copyWith(hasDescription: hasDescription);
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
  Future<void> updateSortField(CategoriesSortField sortField) async {
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
    state = CategoriesFilter.create(
      sortField: CategoriesSortField.name,
      limit: 30,
    );
    await Future.microtask(() {});
  }

  /// Обновить весь фильтр сразу
  Future<void> updateFilter(CategoriesFilter filter) async {
    _debounceTimer?.cancel();
    state = filter;
    await Future.microtask(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Уведомления об изменениях
  // ─────────────────────────────────────────────────────────────────────────

  /// Уведомить о добавлении категории
  void notifyCategoryAdded({String? categoryId}) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerCategoryAdd(categoryId: categoryId);
  }

  /// Уведомить об обновлении категории
  void notifyCategoryUpdated({String? categoryId}) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerCategoryUpdate(categoryId: categoryId);
  }

  /// Уведомить об удалении категории
  void notifyCategoryDeleted({String? categoryId}) {
    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerCategoryDelete(categoryId: categoryId);
  }
}
