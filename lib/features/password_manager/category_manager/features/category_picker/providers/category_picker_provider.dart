import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../models/category_pagination_state.dart';
import 'category_filter_provider.dart';

/// Провайдер для получения отфильтрованного списка категорий с пагинацией
final categoryPickerListProvider =
    AsyncNotifierProvider.family<
      CategoryListNotifier,
      CategoryPaginationState,
      List<CategoryType?>
    >(CategoryListNotifier.new);

/// AsyncNotifier для управления списком категорий с пагинацией
class CategoryListNotifier extends AsyncNotifier<CategoryPaginationState> {
  static const int _pageSize = 20;

  CategoryListNotifier(this.initialTypes);

  final List<CategoryType?> initialTypes;

  @override
  Future<CategoryPaginationState> build() async {
    ref.listen(categoryPickerFilterProvider, (previous, next) {
      if (previous != next) {
        refresh();
      }
    });

    // Загружаем первую страницу
    return await _fetchCategoriesWithFilter(page: 0);
  }

  /// Получить категории с применением текущего фильтра
  Future<CategoryPaginationState> _fetchCategoriesWithFilter({
    required int page,
    List<CategoryCardDto>? existingItems,
  }) async {
    try {
      final filter = ref.read(categoryPickerFilterProvider);
      final categoryDao = await ref.read(categoryDaoProvider.future);

      logDebug(
        'Fetching categories with filter: types=${filter.types}, query="${filter.query}", page=$page',
        tag: 'CategoryListNotifier',
      );

      // Создаем фильтр с пагинацией
      final paginatedFilter = filter.copyWith(
        offset: page * _pageSize,
        limit: _pageSize,
        types: initialTypes.isNotEmpty ? initialTypes : filter.types,
      );

      final newItems = await categoryDao.getCategoryCardsFiltered(
        paginatedFilter,
      );
      final allItems = existingItems != null
          ? [...existingItems, ...newItems]
          : newItems;

      logDebug(
        'Loaded ${newItems.length} categories (total: ${allItems.length})',
        tag: 'CategoryListNotifier',
      );

      return CategoryPaginationState(
        items: allItems,
        hasMore: newItems.length >= _pageSize,
        isLoading: false,
        error: null,
        currentPage: page,
        totalCount: allItems.length,
      );
    } catch (e) {
      return CategoryPaginationState(
        items: existingItems ?? [],
        hasMore: false,
        isLoading: false,
        error: e,
        currentPage: page,
        totalCount: existingItems?.length ?? 0,
      );
    }
  }

  /// Загрузить следующую страницу категорий
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoading ||
        !currentState.hasMore) {
      return;
    }

    // Устанавливаем флаг загрузки
    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    // Загружаем следующую страницу
    final nextPage = currentState.currentPage + 1;
    final newState = await _fetchCategoriesWithFilter(
      page: nextPage,
      existingItems: currentState.items,
    );

    state = AsyncValue.data(newState);
  }

  /// Обновить список категорий (сброс пагинации)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCategoriesWithFilter(page: 0));
  }
}
