import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/models/category_picker_filter.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:result_dart/result_dart.dart';

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

    return await _fetchCategoriesWithFilter(page: 0);
  }

  Future<CategoryPaginationState> _fetchCategoriesWithFilter({
    required int page,
    List<CategoryCardDto>? existingItems,
  }) async {
    try {
      final filter = ref.read(categoryPickerFilterProvider);
      final repos = await ref.read(vaultRepositories.future);

      logDebug(
        'Fetching categories with filter: types=${filter.types}, query="${filter.query}", page=$page',
        tag: 'CategoryListNotifier',
      );

      final result = await repos.category.getAllCategories();
      final allCategories = result.getOrThrow();
      final effectiveTypes = initialTypes.isNotEmpty
          ? initialTypes
          : filter.types;
      final filteredCategories = _applyFilter(
        allCategories,
        filter.copyWith(types: effectiveTypes),
      );
      final newItems = filteredCategories
          .skip(page * _pageSize)
          .take(_pageSize)
          .toList();
      final allItems = existingItems != null
          ? [...existingItems, ...newItems]
          : newItems;

      logDebug(
        'Loaded ${newItems.length} categories (total: ${allItems.length})',
        tag: 'CategoryListNotifier',
      );

      return CategoryPaginationState(
        items: allItems,
        hasMore: allItems.length < filteredCategories.length,
        isLoading: false,
        error: null,
        currentPage: page,
        totalCount: filteredCategories.length,
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

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoading ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    final nextPage = currentState.currentPage + 1;
    final newState = await _fetchCategoriesWithFilter(
      page: nextPage,
      existingItems: currentState.items,
    );

    state = AsyncValue.data(newState);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCategoriesWithFilter(page: 0));
  }

  List<CategoryCardDto> _applyFilter(
    List<CategoryCardDto> categories,
    CategoryPickerFilter filter,
  ) {
    final query = filter.query.trim().toLowerCase();
    var result = categories;

    if (query.isNotEmpty) {
      result = result
          .where((category) => category.name.toLowerCase().contains(query))
          .toList();
    }

    if (filter.color != null && filter.color!.trim().isNotEmpty) {
      final color = _parseColor(filter.color!);
      if (color != null) {
        result = result.where((category) => category.color == color).toList();
      }
    }

    if (filter.hasIcon != null) {
      result = result
          .where((category) => (category.iconRefId != null) == filter.hasIcon)
          .toList();
    }

    return [...result]..sort((a, b) => a.name.compareTo(b.name));
  }

  int? _parseColor(String value) {
    final normalized = value.trim().replaceFirst('#', '');
    return int.tryParse(normalized, radix: 16);
  }
}
