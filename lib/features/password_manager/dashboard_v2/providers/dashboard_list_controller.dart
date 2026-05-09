import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/app_error.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/models/dto/base_card_extensions.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:result_dart/result_dart.dart';

import '../data/main_db_dashboard_repository.dart';
import '../models/dashboard_entity_type.dart';
import '../models/dashboard_filter_state.dart';
import '../models/dashboard_list_state.dart';
import '../models/dashboard_query.dart';
import 'dashboard_filter_provider.dart';

final dashboardListControllerProvider = AsyncNotifierProvider.autoDispose
    .family<
      DashboardListController,
      DashboardListState,
      DashboardEntityType
    >(DashboardListController.new);

final class DashboardListController extends AsyncNotifier<DashboardListState> {
  DashboardListController(this.entityType);

  static const _logTag = 'DashboardV2ListController';

  final DashboardEntityType entityType;

  @override
  Future<DashboardListState> build() async {
    final filters = ref.watch(dashboardFilterProvider);
    return _loadFirstPage(filters);
  }

  Future<void> refresh() async {
    final filters = ref.read(dashboardFilterProvider);
    state = const AsyncLoading<DashboardListState>();
    state = await AsyncValue.guard(() => _loadFirstPage(filters));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, clearLastError: true));

    final filters = ref.read(dashboardFilterProvider);
    final result = await ref.read(dashboardRepositoryProvider).load(
      DashboardQuery(entityType: entityType, filters: filters, page: current.page + 1),
    );

    result.fold(
      (page) {
        state = AsyncData(
          current.copyWith(
            items: [...current.items, ...page.items],
            totalCount: page.totalCount,
            page: current.page + 1,
            isLoadingMore: false,
            clearLastError: true,
          ),
        );
      },
      (error) {
        state = AsyncData(current.copyWith(isLoadingMore: false, lastError: error));
      },
    );
  }

  Future<AppError?> toggleFavorite(BaseCardDto item) {
    return _applyItemMutation(
      item,
      optimisticValue: item.copyWithBase(isFavorite: !item.isFavorite),
      operation: () => ref.read(dashboardRepositoryProvider).setFavorite(
        entityType: entityType,
        id: item.id,
        value: !item.isFavorite,
      ),
    );
  }

  Future<AppError?> togglePinned(BaseCardDto item) {
    return _applyItemMutation(
      item,
      optimisticValue: item.copyWithBase(isPinned: !item.isPinned),
      operation: () => ref.read(dashboardRepositoryProvider).setPinned(
        entityType: entityType,
        id: item.id,
        value: !item.isPinned,
      ),
    );
  }

  Future<AppError?> toggleArchived(BaseCardDto item) {
    return _applyItemMutation(
      item,
      optimisticValue: item.copyWithBase(isArchived: !item.isArchived),
      operation: () => ref.read(dashboardRepositoryProvider).setArchived(
        entityType: entityType,
        id: item.id,
        value: !item.isArchived,
      ),
    );
  }

  Future<AppError?> softDelete(BaseCardDto item) {
    return _applyItemMutation(
      item,
      removeFromList: true,
      operation: () => ref.read(dashboardRepositoryProvider).softDelete(
        entityType: entityType,
        id: item.id,
      ),
    );
  }

  Future<DashboardListState> _loadFirstPage(DashboardFilterState filters) async {
    final result = await ref.read(dashboardRepositoryProvider).load(
      DashboardQuery(entityType: entityType, filters: filters, page: 0),
    );

    return result.fold(
      (page) => DashboardListState(
        items: page.items,
        totalCount: page.totalCount,
        page: 0,
        pageSize: filters.pageSize,
      ),
      (error) {
        logWarning(
          'Dashboard v2 first page load failed',
          tag: _logTag,
          data: {'entityType': entityType.id, 'error': error.message},
        );
        return DashboardListState.empty(pageSize: filters.pageSize).copyWith(
          lastError: error,
        );
      },
    );
  }

  Future<AppError?> _applyItemMutation(
    BaseCardDto item, {
    BaseCardDto? optimisticValue,
    bool removeFromList = false,
    required AsyncResultDart<bool, AppError> Function() operation,
  }) async {
    final current = state.value;
    if (current == null) return null;

    final optimisticItems = removeFromList
        ? current.items.where((candidate) => candidate.id != item.id).toList()
        : [
            for (final candidate in current.items)
              if (candidate.id == item.id) optimisticValue ?? candidate else candidate,
          ];

    state = AsyncData(
      current.copyWith(
        items: optimisticItems,
        totalCount: removeFromList ? current.totalCount - 1 : current.totalCount,
        clearLastError: true,
      ),
    );

    AppError? error;
    final result = await operation();
    result.fold((_) {}, (failure) => error = failure);

    if (error != null) {
      state = AsyncData(current.copyWith(lastError: error));
    }

    return error;
  }
}
