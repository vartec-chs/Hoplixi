import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/dto/icon_dto.dart';
import 'package:hoplixi/main_store/models/filter/icons_filter.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import '../models/icon_picker_state.dart';
import 'icon_picker_filter_provider.dart';

/// Провайдер для управления списком иконок в picker
final iconPickerListProvider =
    AsyncNotifierProvider.autoDispose<IconPickerListNotifier, IconPickerState>(
      () {
        return IconPickerListNotifier();
      },
    );

/// Notifier для управления списком иконок с пагинацией
class IconPickerListNotifier extends AsyncNotifier<IconPickerState> {
  static const int _pageSize = 20;

  @override
  Future<IconPickerState> build() async {
    // Слушаем изменения поискового запроса
    ref.listen(iconPickerSearchProvider, (previous, next) {
      if (previous != next) {
        refresh();
      }
    });

    // Загружаем первую страницу
    return await _fetchIcons(page: 0);
  }

  /// Получить иконки с применением текущего фильтра
  Future<IconPickerState> _fetchIcons({
    required int page,
    List<IconCardDto>? existingItems,
  }) async {
    try {
      final searchQuery = ref.read(iconPickerSearchProvider);
      final iconDao = await ref.read(iconDaoProvider.future);

      // Создаем фильтр с пагинацией и поиском
      final filter = IconsFilter(
        query: searchQuery,
        sortField: IconsSortField.name,
        limit: _pageSize,
        offset: page * _pageSize,
      );

      final newItems = await iconDao.getIconCardsFiltered(filter);
      final allItems = existingItems != null
          ? [...existingItems, ...newItems]
          : newItems;

      return IconPickerState(
        items: allItems,
        hasMore: newItems.length >= _pageSize,
        isLoading: false,
        error: null,
        currentPage: page,
      );
    } catch (e) {
      return IconPickerState(
        items: existingItems ?? [],
        hasMore: false,
        isLoading: false,
        error: e,
        currentPage: page,
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
    final newState = await _fetchIcons(
      page: nextPage,
      existingItems: currentState.items,
    );

    state = AsyncValue.data(newState);
  }

  /// Обновить список иконок (сброс пагинации)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchIcons(page: 0));
  }
}
