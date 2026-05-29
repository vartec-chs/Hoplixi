import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import '../models/category_manager_filter.dart';

/// Провайдер для управления состоянием фильтра категорий
final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, CategoryManagerFilter>(
      () => CategoryFilterNotifier(),
    );

/// Notifier для управления фильтром категорий
class CategoryFilterNotifier extends Notifier<CategoryManagerFilter> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  CategoryManagerFilter build() {
    // Очищаем таймер при destroy провайдера
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return const CategoryManagerFilter(
      sortField: CategoryManagerSortField.name,
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

  /// Обновить цвет
  Future<void> updateColor(int? color) async {
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
  Future<void> updateSortField(CategoryManagerSortField sortField) async {
    state = state.copyWith(sortField: sortField);
    await Future.microtask(() {});
  }

  /// Обновить лимит
  Future<void> updateLimit(int? limit) async {
    state = state.copyWith(limit: limit ?? 30);
    await Future.microtask(() {});
  }

  /// Обновить offset
  Future<void> updateOffset(int? offset) async {
    state = state.copyWith(offset: offset ?? 0);
    await Future.microtask(() {});
  }

  /// Сбросить фильтр к начальному состоянию
  Future<void> reset() async {
    _debounceTimer?.cancel();
    state = const CategoryManagerFilter(
      sortField: CategoryManagerSortField.name,
      limit: 30,
    );
    await Future.microtask(() {});
  }

  /// Обновить весь фильтр сразу
  Future<void> updateFilter(CategoryManagerFilter filter) async {
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
        .read(dashboardListRefreshTriggerProvider.notifier)
        .triggerCategoryAdd(categoryId: categoryId);
  }

  /// Уведомить об обновлении категории
  void notifyCategoryUpdated({String? categoryId}) {
    ref
        .read(dashboardListRefreshTriggerProvider.notifier)
        .triggerCategoryUpdate(categoryId: categoryId);
  }

  /// Уведомить об удалении категории
  void notifyCategoryDeleted({String? categoryId}) {
    ref
        .read(dashboardListRefreshTriggerProvider.notifier)
        .triggerCategoryDelete(categoryId: categoryId);
  }
}
