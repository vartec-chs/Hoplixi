import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/history/models/history_v2_models.dart';
import 'package:hoplixi/features/password_manager/history/services/history_repository.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

final historyControllerProvider =
    AsyncNotifierProvider.family<
      HistoryController,
      HistoryScreenState,
      HistoryScope
    >(HistoryController.new);

class HistoryController extends AsyncNotifier<HistoryScreenState> {
  HistoryController(this.scope);

  final HistoryScope scope;
  List<dynamic> _history = const [];
  dynamic _current;

  @override
  Future<HistoryScreenState> build() async {
    final query = HistoryQueryState(
      entityType: scope.entityType,
      entityId: scope.entityId,
    );
    return _load(query);
  }

  Future<void> refresh() async {
    final currentState = state.value;
    if (currentState == null) return;
    state = AsyncValue.data(
      currentState.copyWith(isRefreshing: true, error: null),
    );
    state = await AsyncValue.guard(() => _load(currentState.query));
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.canLoadMore) return;
    state = await AsyncValue.guard(
      () =>
          _load(currentState.query.copyWith(page: currentState.query.page + 1)),
    );
  }

  Future<void> setSearch(String value) async {
    final currentState = state.value;
    if (currentState == null) return;
    state = await AsyncValue.guard(
      () => _load(currentState.query.copyWith(search: value, resetPage: true)),
    );
  }

  Future<void> setActionFilter(HistoryActionFilter filter) async {
    final currentState = state.value;
    if (currentState == null) return;
    state = await AsyncValue.guard(
      () => _load(
        currentState.query.copyWith(actionFilter: filter, resetPage: true),
      ),
    );
  }

  Future<void> setDatePreset(HistoryDatePreset preset) async {
    final currentState = state.value;
    if (currentState == null) return;
    state = await AsyncValue.guard(
      () => _load(
        currentState.query.copyWith(datePreset: preset, resetPage: true),
      ),
    );
  }

  Future<void> selectRevision(String revisionId) async {
    final currentState = state.value;
    if (currentState == null) return;
    final repository = await _repository();
    final detail = repository.buildDetail(
      entityType: scope.entityType,
      revisionId: revisionId,
      history: _history.cast(),
      current: _current,
    );
    state = AsyncValue.data(
      currentState.copyWith(
        selectedRevisionId: revisionId,
        selectedDetail: detail,
        error: null,
      ),
    );
  }

  Future<bool> restoreRevision(String revisionId) async {
    final currentState = state.value;
    if (currentState == null) return false;
    state = AsyncValue.data(
      currentState.copyWith(isRestoring: true, error: null),
    );
    try {
      final repository = await _repository();
      await repository.restoreRevision(
        entityType: scope.entityType,
        revisionId: revisionId,
        history: _history.cast(),
      );
      ref
          .read(dataRefreshTriggerProvider.notifier)
          .triggerEntityUpdate(scope.entityType, entityId: scope.entityId);
      final reloaded = await _load(currentState.query);
      state = AsyncValue.data(reloaded);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> deleteRevision(String revisionId) async {
    final currentState = state.value;
    if (currentState == null) return false;
    state = AsyncValue.data(
      currentState.copyWith(isRefreshing: true, error: null),
    );
    try {
      final repository = await _repository();
      final deleted = await repository.deleteRevision(
        entityType: scope.entityType,
        revisionId: revisionId,
      );
      final reloaded = await _load(currentState.query);
      state = AsyncValue.data(reloaded);
      return deleted;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> clearAllHistory() async {
    final currentState = state.value;
    if (currentState == null) return false;
    state = AsyncValue.data(
      currentState.copyWith(isRefreshing: true, error: null),
    );
    try {
      final repository = await _repository();
      final cleared = await repository.clearAllHistory(
        entityType: scope.entityType,
        entityId: scope.entityId,
      );
      final reloaded = await _load(
        currentState.query.copyWith(resetPage: true),
      );
      state = AsyncValue.data(reloaded);
      return cleared;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<HistoryScreenState> _load(HistoryQueryState query) async {
    final repository = await _repository();
    final result = await repository.loadHistory(query);
    _history = result.history;
    _current = result.current;
    final selectedRevisionId = _pickSelectedRevisionId(
      preferred: state.value?.selectedRevisionId,
      timelineItems: result.timelineItems,
    );
    final detail = selectedRevisionId == null
        ? null
        : repository.buildDetail(
            entityType: scope.entityType,
            revisionId: selectedRevisionId,
            history: result.history,
            current: result.current,
          );
    return HistoryScreenState(
      query: query,
      timelineItems: result.timelineItems,
      totalCount: result.totalCount,
      selectedRevisionId: selectedRevisionId,
      selectedDetail: detail,
      isRefreshing: false,
      isRestoring: false,
      canLoadMore: result.canLoadMore,
      hasLiveEntity: result.current != null,
    );
  }

  String? _pickSelectedRevisionId({
    required String? preferred,
    required List<HistoryTimelineItem> timelineItems,
  }) {
    if (preferred != null &&
        timelineItems.any((item) => item.revisionId == preferred)) {
      return preferred;
    }
    return timelineItems.isEmpty ? null : timelineItems.first.revisionId;
  }

  Future<HistoryRepository> _repository() async {
    final manager = await ref.read(mainStoreManagerProvider.future);
    final store = manager?.currentStore;
    if (store == null) {
      throw StateError('Main store is not initialized.');
    }
    return HistoryRepository(store);
  }
}
