import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/history/models/history_item.dart';
import 'package:hoplixi/features/password_manager/history/models/history_list_state.dart';
import 'package:hoplixi/features/password_manager/history/models/history_v2_models.dart';
import 'package:hoplixi/features/password_manager/history/providers/history_search_provider.dart';
import 'package:hoplixi/features/password_manager/history/services/history_repository.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';

/// Константа размера страницы для пагинации истории
const int kHistoryPageSize = 20;

/// Параметры для провайдера истории
class HistoryParams {
  final EntityType entityType;
  final String entityId;

  const HistoryParams({required this.entityType, required this.entityId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryParams &&
        other.entityType == entityType &&
        other.entityId == entityId;
  }

  @override
  int get hashCode => entityType.hashCode ^ entityId.hashCode;
}

/// Провайдер параметров истории.
final historyParamsProvider =
    NotifierProvider.autoDispose<HistoryParamsNotifier, HistoryParams?>(
      HistoryParamsNotifier.new,
    );

class HistoryParamsNotifier extends Notifier<HistoryParams?> {
  @override
  HistoryParams? build() => null;

  void setParams(HistoryParams params) {
    state = params;
  }

  void clear() {
    state = null;
  }
}

final historyListProvider =
    AsyncNotifierProvider.autoDispose<HistoryListNotifier, HistoryListState>(
      HistoryListNotifier.new,
    );

class HistoryListNotifier extends AsyncNotifier<HistoryListState> {
  static const String _logTag = 'HistoryListNotifier';

  HistoryParams get _params {
    final params = ref.read(historyParamsProvider);
    if (params == null) {
      throw StateError(
        'HistoryParams не установлены. '
        'Установите historyParamsProvider перед использованием historyListProvider.',
      );
    }
    return params;
  }

  int get pageSize => kHistoryPageSize;

  @override
  Future<HistoryListState> build() async {
    final params = ref.watch(historyParamsProvider);
    if (params == null) {
      return const HistoryListState(
        items: [],
        isLoading: false,
        hasMore: false,
        totalCount: 0,
      );
    }

    final searchState = ref.watch(historySearchProvider);
    return _loadPage(page: 1, searchQuery: searchState.query);
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.currentPage + 1;
    final searchState = ref.read(historySearchProvider);
    final nextState = await _loadPage(
      page: nextPage,
      searchQuery: searchState.query,
    );

    state = AsyncValue.data(nextState);
  }

  Future<void> refresh() async {
    final searchState = ref.read(historySearchProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _loadPage(page: 1, searchQuery: searchState.query),
    );
  }

  Future<bool> deleteHistoryItem(String historyId) async {
    try {
      final repository = await _repository();
      final params = _params;
      final deleted = await repository.deleteRevision(
        entityType: params.entityType,
        revisionId: historyId,
      );
      await refresh();
      return deleted;
    } catch (e, st) {
      logError(
        'Ошибка удаления записи истории',
        tag: _logTag,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<bool> deleteAllHistory() async {
    try {
      final repository = await _repository();
      final params = _params;
      final cleared = await repository.clearAllHistory(
        entityType: params.entityType,
        entityId: params.entityId,
      );
      await refresh();
      return cleared;
    } catch (e, st) {
      logError(
        'Ошибка очистки истории',
        tag: _logTag,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<HistoryListState> _loadPage({
    required int page,
    String? searchQuery,
  }) async {
    try {
      final params = _params;
      final repository = await _repository();
      final result = await repository.loadHistory(
        HistoryQueryState(
          entityType: params.entityType,
          entityId: params.entityId,
          search: searchQuery ?? '',
          page: page,
          pageSize: pageSize,
        ),
      );

      return HistoryListState(
        items: result.timelineItems
            .map(
              (item) => HistoryItem(
                id: item.revisionId,
                originalEntityId: item.originalEntityId,
                entityType: params.entityType,
                action: item.action,
                title: item.title,
                subtitle: item.subtitle,
                actionAt: item.actionAt,
              ),
            )
            .toList(),
        isLoading: false,
        hasMore: result.canLoadMore,
        currentPage: page,
        totalCount: result.totalCount,
      );
    } catch (e, st) {
      logError(
        'Ошибка загрузки истории',
        tag: _logTag,
        error: e,
        stackTrace: st,
      );
      return HistoryListState(error: e.toString());
    }
  }

  Future<HistoryRepository> _repository() async {
    final historyAssembly = await ref.read(
      vaultHistoryServiceAssemblyProvider.future,
    );
    return HistoryRepository(historyAssembly);
  }
}
