import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_db/core/models/dto/category_dto.dart';
import 'package:hoplixi/main_db/core/models/filter/categories_filter.dart';
import 'package:hoplixi/main_db/old/provider/dao_providers.dart';

import '../../providers/manager_refresh_trigger_provider.dart';
import '../models/category_pagination_state.dart';
import 'category_filter_provider.dart';

final categoryListProvider =
    AsyncNotifierProvider.autoDispose<
      CategoryListNotifier,
      CategoryPaginationState
    >(CategoryListNotifier.new);

class CategoryListNotifier extends AsyncNotifier<CategoryPaginationState> {
  static const int _pageSize = 30;

  @override
  Future<CategoryPaginationState> build() async {
    final filter = ref.watch(categoryFilterProvider);
    ref.listen(managerRefreshTriggerProvider, (previous, next) {
      if (!ref.mounted) {
        return;
      }
      if (next.resourceType == ManagerResourceType.category ||
          next.resourceType == null) {
        refresh();
      }
    });
    return _fetchCategoriesWithFilter(filter: filter, page: 0);
  }

  Future<CategoryPaginationState> _fetchCategoriesWithFilter({
    required CategoriesFilter filter,
    required int page,
    List<CategoryCardDto>? existingItems,
  }) async {
    try {
      final categoryDao = await ref.read(categoryDaoProvider.future);
      if (!ref.mounted) {
        return _fallbackState(page: page, existingItems: existingItems);
      }

      final paginatedFilter = filter.copyWith(
        offset: page * _pageSize,
        limit: _pageSize,
      );

      final newItems = await categoryDao.getCategoryCardsFiltered(
        paginatedFilter,
      );
      final allItems = existingItems != null
          ? [...existingItems, ...newItems]
          : newItems;

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
        items: existingItems ?? const [],
        hasMore: false,
        isLoading: false,
        error: e,
        currentPage: page,
        totalCount: existingItems?.length ?? 0,
      );
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoading ||
        !currentState.hasMore ||
        !ref.mounted) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    final nextPage = currentState.currentPage + 1;
    final filter = ref.read(categoryFilterProvider);
    final newState = await _fetchCategoriesWithFilter(
      filter: filter,
      page: nextPage,
      existingItems: currentState.items,
    );

    if (!ref.mounted) {
      return;
    }

    state = AsyncValue.data(newState);
  }

  Future<void> refresh() async {
    if (!ref.mounted) {
      return;
    }

    state = const AsyncValue.loading();
    final filter = ref.read(categoryFilterProvider);
    final nextState = await _fetchCategoriesWithFilter(filter: filter, page: 0);

    if (!ref.mounted) {
      return;
    }

    state = AsyncValue.data(nextState);
  }

  CategoryPaginationState _fallbackState({
    required int page,
    List<CategoryCardDto>? existingItems,
  }) {
    return CategoryPaginationState(
      items: existingItems ?? const [],
      hasMore: false,
      isLoading: false,
      error: null,
      currentPage: page,
      totalCount: existingItems?.length ?? 0,
    );
  }
}
