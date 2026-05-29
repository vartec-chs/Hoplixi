import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/icon_dto.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';

import '../../providers/manager_refresh_trigger_provider.dart';
import '../models/icon_manager_filter.dart';
import '../models/icon_pagination_state.dart';
import 'icon_filter_provider.dart';

/// Провайдер для получения отфильтрованного списка иконок
final iconListProvider =
    AsyncNotifierProvider<IconListNotifier, IconPaginationState>(
  IconListNotifier.new,
);

/// AsyncNotifier для управления списком иконок
class IconListNotifier extends AsyncNotifier<IconPaginationState> {
  @override
  Future<IconPaginationState> build() async {
    // Слушаем изменения фильтра для автоматической перезагрузки
    ref.listen(iconFilterProvider, (previous, next) {
      if (previous != next) {
        refresh();
      }
    });

    // Слушаем триггер обновления иконок
    ref.listen(managerRefreshTriggerProvider, (previous, next) {
      if (next.resourceType == ManagerResourceType.icon ||
          next.resourceType == null) {
        refresh();
      }
    });

    // Загружаем данные
    return await _fetchIconsWithFilter();
  }

  /// Получить иконки с применением текущего фильтра
  Future<IconPaginationState> _fetchIconsWithFilter() async {
    try {
      final filter = ref.read(iconFilterProvider);
      final repos = await ref.read(vaultRepositories.future);

      final result = await repos.icon.getCustomIcons();
      final allIcons = result.getOrThrow();

      // Фильтрация in-memory
      var filtered = allIcons.where((icon) {
        if (filter.query.isNotEmpty &&
            !icon.name.toLowerCase().contains(filter.query.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();

      // Сортировка
      switch (filter.sortField) {
        case IconManagerSortField.name:
          filtered.sort((a, b) => a.name.compareTo(b.name));
        case IconManagerSortField.createdAt:
          filtered.sort((a, b) => a.name.compareTo(b.name));
        case IconManagerSortField.modifiedAt:
          filtered.sort((a, b) => a.name.compareTo(b.name));
      }

      return IconPaginationState(
        items: filtered,
        hasMore: false,
        isLoading: false,
        error: null,
        currentPage: 0,
        totalCount: filtered.length,
      );
    } catch (e) {
      return IconPaginationState(
        items: const [],
        hasMore: false,
        isLoading: false,
        error: e,
        currentPage: 0,
        totalCount: 0,
      );
    }
  }

  /// Загрузить следующую страницу иконок
  Future<void> loadMore() async {
    // В текущей реализации манагера грузим всё сразу
  }

  /// Обновить список иконок
  Future<void> refresh() async {
    if (!ref.mounted) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchIconsWithFilter());
  }
}
