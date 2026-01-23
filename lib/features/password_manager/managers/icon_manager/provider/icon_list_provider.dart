import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import '../models/icon_pagination_state.dart';
import 'icon_filter_provider.dart';

/// Провайдер для получения отфильтрованного списка иконок с пагинацией
final iconListProvider =
    AsyncNotifierProvider<IconListNotifier, IconPaginationState>(() {
      return IconListNotifier();
    });

/// AsyncNotifier для управления списком иконок с пагинацией
class IconListNotifier extends AsyncNotifier<IconPaginationState> {
  static const int _pageSize = 30;

  @override
  Future<IconPaginationState> build() async {
    // Слушаем изменения фильтра для автоматической перезагрузки
    ref.listen(iconFilterProvider, (previous, next) {
      if (previous != next) {
        refresh();
      }
    });

    // Загружаем первую страницу
    return await _fetchIconsWithFilter(page: 0);
  }

  /// Получить иконки с применением текущего фильтра
  Future<IconPaginationState> _fetchIconsWithFilter({
    required int page,
    List<IconsData>? existingItems,
  }) async {
    try {
      final filter = ref.read(iconFilterProvider);
      final iconDao = await ref.read(iconDaoProvider.future);

      // Создаем фильтр с пагинацией
      final paginatedFilter = filter.copyWith(
        offset: page * _pageSize,
        limit: _pageSize,
      );

      final newItems = await iconDao.getIconsFiltered(paginatedFilter);
      final allItems = existingItems != null
          ? [...existingItems, ...newItems]
          : newItems;

      return IconPaginationState(
        items: allItems,
        hasMore: newItems.length >= _pageSize,
        isLoading: false,
        error: null,
        currentPage: page,
        totalCount: allItems.length,
      );
    } catch (e) {
      return IconPaginationState(
        items: existingItems ?? [],
        hasMore: false,
        isLoading: false,
        error: e,
        currentPage: page,
        totalCount: existingItems?.length ?? 0,
      );
    }
  }

  /// Загрузить следующую страницу иконок
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
    final newState = await _fetchIconsWithFilter(
      page: nextPage,
      existingItems: currentState.items,
    );

    state = AsyncValue.data(newState);
  }

  /// Обновить список иконок (сброс пагинации)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchIconsWithFilter(page: 0));
  }
}
