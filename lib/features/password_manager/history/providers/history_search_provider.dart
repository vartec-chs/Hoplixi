import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/history/models/history_search_state.dart';

/// Провайдер для управления поиском в истории
///
/// Выделен отдельно для возможности:
/// - Добавления фильтров по дате
/// - Добавления фильтров по типу действия
/// - Расширения логики поиска
final historySearchProvider =
    NotifierProvider.autoDispose<HistorySearchNotifier, HistorySearchState>(
      HistorySearchNotifier.new,
    );

/// Нотификатор для управления поиском в истории
class HistorySearchNotifier extends Notifier<HistorySearchState> {
  @override
  HistorySearchState build() {
    return const HistorySearchState();
  }

  /// Обновить поисковый запрос
  void updateQuery(String query) {
    state = state.copyWith(query: query, isSearching: query.isNotEmpty);
  }

  /// Очистить поиск
  void clearSearch() {
    state = const HistorySearchState();
  }

  /// Начать поиск
  void startSearch() {
    state = state.copyWith(isSearching: true);
  }

  /// Завершить поиск
  void endSearch() {
    state = state.copyWith(isSearching: false);
  }

  // ============================================
  // Методы для будущего расширения фильтрами
  // ============================================

  // /// Установить фильтр по действию
  // void setActionFilter(String? action) {
  //   state = state.copyWith(actionFilter: action);
  // }

  // /// Установить диапазон дат
  // void setDateRange(DateTime? from, DateTime? to) {
  //   state = state.copyWith(dateFrom: from, dateTo: to);
  // }

  // /// Сбросить все фильтры
  // void resetFilters() {
  //   state = state.copyWith(
  //     actionFilter: null,
  //     dateFrom: null,
  //     dateTo: null,
  //   );
  // }
}
