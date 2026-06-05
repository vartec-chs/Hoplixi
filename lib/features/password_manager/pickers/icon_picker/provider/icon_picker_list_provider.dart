import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

import '../models/icon_picker_state.dart';

/// Провайдер для управления списком иконок в picker
final iconPickerListProvider = AsyncNotifierProvider.autoDispose
    .family<IconPickerListNotifier, IconPickerState, String>(
      IconPickerListNotifier.new,
    );

/// Notifier для управления списком иконок с пагинацией
class IconPickerListNotifier extends AsyncNotifier<IconPickerState> {
  static const int _pageSize = 20;

  IconPickerListNotifier(this.arg);

  final String arg;

  @override
  FutureOr<IconPickerState> build() async {
    // Загружаем первую страницу
    return await _fetchIcons(page: 0);
  }

  /// Получить иконки с применением текущего фильтра
  Future<IconPickerState> _fetchIcons({
    required int page,
    List<CustomIconCardDto>? existingItems,
  }) async {
    try {
      final searchQuery = arg.trim();
      final repos = await ref.read(vaultRepositories.future);
      final offset = page * _pageSize;
      final pageResult = await repos.icon.getCustomIconsForPicker(
        query: searchQuery,
        limit: _pageSize,
        offset: offset,
      );
      final totalResult = await repos.icon.countCustomIconsForPicker(
        query: searchQuery,
      );

      final newItems = pageResult.getOrThrow();
      final totalItems = totalResult.getOrThrow();
      final allItems = existingItems != null
          ? [...existingItems, ...newItems]
          : newItems;

      return IconPickerState(
        items: allItems,
        hasMore: offset + newItems.length < totalItems,
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
