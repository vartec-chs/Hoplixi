import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/models/tag_picker_filter.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';

import '../models/tag_pagination_state.dart';
import 'tag_filter_provider.dart';

/// Провайдер для получения отфильтрованного списка тегов с пагинацией
final tagPickerListProvider =
    AsyncNotifierProvider.autoDispose<TagListNotifier, TagPaginationState>(
      TagListNotifier.new,
    );

/// AsyncNotifier для управления списком тегов с пагинацией
class TagListNotifier extends AsyncNotifier<TagPaginationState> {
  static const int _pageSize = 20;

  @override
  Future<TagPaginationState> build() async {
    ref.listen(tagPickerFilterProvider, (previous, next) {
      if (previous != next) {
        refresh();
      }
    });

    return await _fetchTagsWithFilter(page: 0);
  }

  Future<TagPaginationState> _fetchTagsWithFilter({
    required int page,
    List<TagCardDto>? existingItems,
  }) async {
    try {
      final filter = ref.read(tagPickerFilterProvider);
      final repos = await ref.read(vaultRepositories.future);
      final result = await repos.tag.getAllTags();
      final allTags = result.getOrThrow();

      final filteredTags = _applyFilter(allTags, filter);
      final newItems = filteredTags
          .skip(page * _pageSize)
          .take(_pageSize)
          .toList();
      final allItems = existingItems != null
          ? [...existingItems, ...newItems]
          : newItems;

      return TagPaginationState(
        items: allItems,
        hasMore: allItems.length < filteredTags.length,
        isLoading: false,
        error: null,
        currentPage: page,
        totalCount: filteredTags.length,
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

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoading ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    final nextPage = currentState.currentPage + 1;
    final newState = await _fetchTagsWithFilter(
      page: nextPage,
      existingItems: currentState.items,
    );

    state = AsyncValue.data(newState);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTagsWithFilter(page: 0));
  }

  List<TagCardDto> _applyFilter(List<TagCardDto> tags, TagPickerFilter filter) {
    final query = filter.query.trim().toLowerCase();
    var result = tags;

    if (query.isNotEmpty) {
      result = result
          .where((tag) => tag.name.toLowerCase().contains(query))
          .toList();
    }

    if (filter.color != null && filter.color!.trim().isNotEmpty) {
      final color = _parseColor(filter.color!);
      if (color != null) {
        result = result.where((tag) => tag.color == color).toList();
      }
    }

    return [...result]..sort((a, b) => a.name.compareTo(b.name));
  }

  int? _parseColor(String value) {
    final normalized = value.trim().replaceFirst('#', '');
    return int.tryParse(normalized, radix: 16);
  }
}
