import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../models/tag_pagination_state.dart';
import 'tag_filter_provider.dart';

/// Провайдер для получения отфильтрованного списка тегов с пагинацией
final tagPickerListProvider = AsyncNotifierProvider.autoDispose
    .family<TagListNotifier, TagPaginationState, List<TagType?>>(
      TagListNotifier.new,
    );

/// AsyncNotifier для управления списком тегов с пагинацией
class TagListNotifier extends AsyncNotifier<TagPaginationState> {
  static const int _pageSize = 20;

  TagListNotifier(this.initialTypes);

  final List<TagType?> initialTypes;

  @override
  Future<TagPaginationState> build() async {
    // Слушаем изменения фильтра для автоматической перезагрузки
    ref.listen(tagPickerFilterProvider, (previous, next) {
      if (previous != next) {
        refresh();
      }
    });

    // Загружаем первую страницу
    return await _fetchTagsWithFilter(page: 0);
  }

  /// Получить теги с применением текущего фильтра
  Future<TagPaginationState> _fetchTagsWithFilter({
    required int page,
    List<TagCardDto>? existingItems,
  }) async {
    try {
      final filter = ref.read(tagPickerFilterProvider);
      final tagDao = await ref.read(tagDaoProvider.future);

      // Создаем фильтр с пагинацией
      final paginatedFilter = filter.copyWith(
        offset: page * _pageSize,
        limit: _pageSize,
        types: initialTypes.isNotEmpty ? initialTypes : filter.types,
      );

      final newItems = await tagDao.getTagCardsFiltered(paginatedFilter);
      final allItems = existingItems != null
          ? [...existingItems, ...newItems]
          : newItems;

      return TagPaginationState(
        items: allItems,
        hasMore: newItems.length >= _pageSize,
        isLoading: false,
        error: null,
        currentPage: page,
        totalCount: allItems.length,
      );
    } catch (e) {
      return TagPaginationState(
        items: existingItems ?? [],
        hasMore: false,
        isLoading: false,
        error: e,
        currentPage: page,
        totalCount: existingItems?.length ?? 0,
      );
    }
  }

  /// Загрузить следующую страницу тегов
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
    final newState = await _fetchTagsWithFilter(
      page: nextPage,
      existingItems: currentState.items,
    );

    state = AsyncValue.data(newState);
  }

  /// Обновить список тегов (сброс пагинации)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTagsWithFilter(page: 0));
  }
}
