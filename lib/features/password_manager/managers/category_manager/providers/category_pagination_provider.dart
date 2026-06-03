import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

import '../../providers/manager_refresh_trigger_provider.dart';
import '../models/category_manager_filter.dart';
import '../models/category_pagination_state.dart';
import 'category_filter_provider.dart';

final categoryListProvider =
    AsyncNotifierProvider.autoDispose<
      CategoryListNotifier,
      CategoryPaginationState
    >(CategoryListNotifier.new);

class CategoryListNotifier extends AsyncNotifier<CategoryPaginationState> {
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
    return _fetchCategoriesWithFilter(filter: filter);
  }

  Future<CategoryPaginationState> _fetchCategoriesWithFilter({
    required CategoryManagerFilter filter,
  }) async {
    try {
      final repos = await ref.read(vaultRepositories.future);
      if (!ref.mounted) {
        return CategoryPaginationState.initial();
      }

      final result = await repos.category.getAllCategories();
      final allCategories = result.getOrThrow();

      // Фильтрация in-memory (т.к. репозиторий пока не поддерживает фильтры)
      var filtered = allCategories.where((c) {
        if (filter.query.isNotEmpty &&
            !c.name.toLowerCase().contains(filter.query.toLowerCase())) {
          return false;
        }
        if (filter.color != null && c.color != filter.color) {
          return false;
        }
        if (filter.hasIcon != null) {
          final hasIcon = c.iconRefId != null;
          if (hasIcon != filter.hasIcon) return false;
        }
        return true;
      }).toList();

      // Сортировка
      switch (filter.sortField) {
        case CategoryManagerSortField.name:
          filtered.sort((a, b) => a.name.compareTo(b.name));
        case CategoryManagerSortField.createdAt:
          // В CategoryCardDto нет createdAt, используем name или ID если нужно
          // Но в CategoryViewDto есть. Для манагера может понадобиться.
          // Оставим по имени пока.
          filtered.sort((a, b) => a.name.compareTo(b.name));
        case CategoryManagerSortField.modifiedAt:
          filtered.sort((a, b) => a.name.compareTo(b.name));
      }

      final totalCount = filtered.length;

      // Пагинация (простая реализация для манагера)
      final items = filtered; // В манагере обычно список небольшой, грузим всё

      return CategoryPaginationState(
        items: items,
        hasMore: false,
        isLoading: false,
        error: null,
        currentPage: 0,
        totalCount: totalCount,
      );
    } catch (e) {
      return CategoryPaginationState(
        items: const [],
        hasMore: false,
        isLoading: false,
        error: e,
        currentPage: 0,
        totalCount: 0,
      );
    }
  }

  Future<void> loadMore() async {
    // В текущей реализации манагера грузим всё сразу
  }

  Future<void> refresh() async {
    if (!ref.mounted) {
      return;
    }

    state = const AsyncValue.loading();
    final filter = ref.read(categoryFilterProvider);
    final nextState = await _fetchCategoriesWithFilter(filter: filter);

    if (!ref.mounted) {
      return;
    }

    state = AsyncValue.data(nextState);
  }
}
