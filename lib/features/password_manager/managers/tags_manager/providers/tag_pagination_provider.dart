import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

import '../../providers/manager_refresh_trigger_provider.dart';
import '../models/tag_manager_filter.dart';
import '../models/tag_pagination_state.dart';
import 'tag_filter_provider.dart';

/// Провайдер для получения отфильтрованного списка тегов
final tagListProvider =
    AsyncNotifierProvider.autoDispose<TagListNotifier, TagPaginationState>(
      TagListNotifier.new,
    );

/// AsyncNotifier для управления списком тегов
class TagListNotifier extends AsyncNotifier<TagPaginationState> {
  @override
  Future<TagPaginationState> build() async {
    // Слушаем изменения фильтра для автоматической перезагрузки
    ref.listen(tagFilterProvider, (previous, next) {
      if (previous != next) {
        refresh();
      }
    });

    // Слушаем триггер обновления тегов
    ref.listen(managerRefreshTriggerProvider, (previous, next) {
      if (next.resourceType == ManagerResourceType.tag ||
          next.resourceType == null) {
        refresh();
      }
    });

    // Загружаем данные
    return await _fetchTagsWithFilter();
  }

  /// Получить теги с применением текущего фильтра
  Future<TagPaginationState> _fetchTagsWithFilter() async {
    try {
      final filter = ref.read(tagFilterProvider);
      final repos = await ref.read(vaultRepositories.future);

      final result = await repos.tag.getAllTags();
      final allTags = result.getOrThrow();

      // Фильтрация in-memory
      var filtered = allTags.where((t) {
        if (filter.query.isNotEmpty &&
            !t.name.toLowerCase().contains(filter.query.toLowerCase())) {
          return false;
        }
        if (filter.color != null && t.color != filter.color) {
          return false;
        }
        return true;
      }).toList();

      // Сортировка
      switch (filter.sortField) {
        case TagManagerSortField.name:
          filtered.sort((a, b) => a.name.compareTo(b.name));
        case TagManagerSortField.createdAt:
          filtered.sort((a, b) => a.name.compareTo(b.name));
        case TagManagerSortField.modifiedAt:
          filtered.sort((a, b) => a.name.compareTo(b.name));
      }

      return TagPaginationState(
        items: filtered,
        hasMore: false,
        isLoading: false,
        error: null,
        currentPage: 0,
        totalCount: filtered.length,
      );
    } catch (e) {
      return TagPaginationState(
        items: const [],
        hasMore: false,
        isLoading: false,
        error: e,
        currentPage: 0,
        totalCount: 0,
      );
    }
  }

  /// Загрузить следующую страницу тегов
  Future<void> loadMore() async {
    // В текущей реализации манагера грузим всё сразу
  }

  /// Обновить список тегов
  Future<void> refresh() async {
    if (!ref.mounted) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTagsWithFilter());
  }
}
