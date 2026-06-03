import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
import 'package:result_dart/result_dart.dart';
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
    List<IconRefCardDto>? existingItems,
  }) async {
    try {
      final searchQuery = ref.read(iconPickerSearchProvider);
      final repos = await ref.read(vaultRepositories.future);
      final result = await repos.icon.getIconRefs();
      final icons = result.getOrThrow();
      final query = searchQuery.trim().toLowerCase();
      final filteredIcons = query.isEmpty
          ? icons
          : icons
                .where(
                  (icon) =>
                      (icon.iconValue ?? '').toLowerCase().contains(query) ||
                      (icon.iconPackId ?? '').toLowerCase().contains(query) ||
                      (icon.customIconId ?? '').toLowerCase().contains(query),
                )
                .toList();

      final newItems = filteredIcons
          .skip(page * _pageSize)
          .take(_pageSize)
          .toList();
      final allItems = existingItems != null
          ? [...existingItems, ...newItems]
          : newItems;

      return IconPickerState(
        items: allItems,
        hasMore: allItems.length < filteredIcons.length,
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
