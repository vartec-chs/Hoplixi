import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/app_error.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/dashboard_filter_tab.dart';
import 'package:hoplixi/main_db/core/old/models/dto/index.dart';
import 'package:result_dart/result_dart.dart';

import '../data/main_db_dashboard_repository.dart';
import '../models/entity_type.dart';
import '../models/dashboard_filter_state.dart';
import '../models/dashboard_list_state.dart';
import '../models/dashboard_list_refresh_state.dart';
import '../models/dashboard_query.dart';
import 'dashboard_filter_provider.dart';
import 'dashboard_list_refresh_trigger_provider.dart';
import 'filter_providers/filter_providers.dart';

final dashboardListControllerProvider = AsyncNotifierProvider.autoDispose
    .family<DashboardListController, DashboardListState, EntityType>(
      DashboardListController.new,
    );

final class DashboardListController extends AsyncNotifier<DashboardListState> {
  DashboardListController(this.entityType);

  static const _logTag = 'DashboardListController';

  final EntityType entityType;

  @override
  Future<DashboardListState> build() async {
    ref.listen(dashboardListRefreshTriggerProvider, (previous, next) {
      if (!ref.mounted) return;
      if (previous?.timestamp == next.timestamp) return;
      if (!_shouldHandleRefreshTrigger(next)) return;

      logDebug(
        'Получен внешний триггер обновления списка',
        tag: _logTag,
        data: {
          'entityType': entityType.id,
          'triggerEntityType': next.entityType?.id,
          'type': next.type.name,
          'entityId': next.entityId,
        },
      );
      refresh();
    });

    final filters = ref.watch(dashboardFilterProvider);
    final entityFilter = _watchEntityFilter();
    return _loadFirstPage(filters, entityFilter);
  }

  bool _shouldHandleRefreshTrigger(DashboardListRefreshState trigger) {
    final triggerEntityType = trigger.entityType;
    return triggerEntityType == null || triggerEntityType == entityType;
  }

  Future<void> refresh() async {
    final filters = ref.read(dashboardFilterProvider);
    final entityFilter = _readEntityFilter();
    state = const AsyncLoading<DashboardListState>();
    state = await AsyncValue.guard(() => _loadFirstPage(filters, entityFilter));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLastError: true),
    );

    final filters = ref.read(dashboardFilterProvider);
    final entityFilter = _readEntityFilter();
    final result = await ref
        .read(dashboardRepositoryProvider)
        .load(
          DashboardQuery(
            entityType: entityType,
            filters: filters,
            entityFilter: entityFilter,
            page: current.page + 1,
          ),
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
        state = AsyncData(
          current.copyWith(isLoadingMore: false, lastError: error),
        );
      },
    );
  }

  Future<AppError?> toggleFavorite(BaseCardDto item) {
    final filters = ref.read(dashboardFilterProvider);
    final isNowFavorite = !item.isFavorite;
    final removeFromList =
        filters.tab == DashboardFilterTab.favorites && !isNowFavorite;

    return _applyItemMutation(
      item,
      optimisticValue: item.copyWithBase(isFavorite: isNowFavorite),
      removeFromList: removeFromList,
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .setFavorite(
            entityType: entityType,
            id: item.id,
            value: isNowFavorite,
          ),
    );
  }

  Future<AppError?> togglePinned(BaseCardDto item) {
    final isNowPinned = !item.isPinned;
    return _applyItemMutation(
      item,
      optimisticValue: item.copyWithBase(isPinned: isNowPinned),
      moveToFront: isNowPinned,
      moveToEnd: !isNowPinned,
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .setPinned(entityType: entityType, id: item.id, value: isNowPinned),
    );
  }

  Future<AppError?> toggleArchived(BaseCardDto item) {
    final filters = ref.read(dashboardFilterProvider);
    final isNowArchived = !item.isArchived;
    final removeFromList =
        (filters.tab == DashboardFilterTab.archived && !isNowArchived) ||
        (filters.tab != DashboardFilterTab.archived && isNowArchived);

    return _applyItemMutation(
      item,
      optimisticValue: item.copyWithBase(isArchived: isNowArchived),
      removeFromList: removeFromList,
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .setArchived(
            entityType: entityType,
            id: item.id,
            value: isNowArchived,
          ),
    );
  }

  Future<AppError?> softDelete(BaseCardDto item) {
    return _applyItemMutation(
      item,
      removeFromList: true,
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .softDelete(entityType: entityType, id: item.id),
    );
  }

  Future<AppError?> permanentDelete(BaseCardDto item) {
    return _applyItemMutation(
      item,
      removeFromList: true,
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .permanentDelete(entityType: entityType, id: item.id),
    );
  }

  Future<AppError?> restore(BaseCardDto item) {
    return _applyItemMutation(
      item,
      optimisticValue: item.copyWithBase(isDeleted: false),
      removeFromList: true,
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .restore(entityType: entityType, id: item.id),
    );
  }

  Future<AppError?> bulkDelete(List<String> ids, {required bool permanently}) {
    return _applyBulkMutation(
      ids,
      operation: () {
        final repository = ref.read(dashboardRepositoryProvider);
        return permanently
            ? repository.bulkPermanentDelete(entityType: entityType, ids: ids)
            : repository.bulkSoftDelete(entityType: entityType, ids: ids);
      },
    );
  }

  Future<AppError?> bulkAssignCategory(List<String> ids, String? categoryId) {
    return _applyBulkMutation(
      ids,
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .bulkAssignCategory(
            entityType: entityType,
            ids: ids,
            categoryId: categoryId,
          ),
    );
  }

  Future<AppError?> bulkAssignTags(List<String> ids, List<String> tagIds) {
    return _applyBulkMutation(
      ids,
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .bulkAssignTags(entityType: entityType, ids: ids, tagIds: tagIds),
    );
  }

  Future<AppError?> bulkSetArchived(List<String> ids, bool isArchived) {
    return _applyBulkMutation(
      ids,
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .bulkSetArchived(entityType: entityType, ids: ids, value: isArchived),
    );
  }

  Future<AppError?> bulkSetFavorite(List<String> ids, bool isFavorite) {
    return _applyBulkMutation(
      ids,
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .bulkSetFavorite(entityType: entityType, ids: ids, value: isFavorite),
    );
  }

  Future<AppError?> bulkSetPinned(List<String> ids, bool isPinned) {
    return _applyBulkMutation(
      ids,
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .bulkSetPinned(entityType: entityType, ids: ids, value: isPinned),
    );
  }

  Future<DashboardListState> _loadFirstPage(
    DashboardFilterState filters,
    Object entityFilter,
  ) async {
    final result = await ref
        .read(dashboardRepositoryProvider)
        .load(
          DashboardQuery(
            entityType: entityType,
            filters: filters,
            entityFilter: entityFilter,
            page: 0,
          ),
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
        return DashboardListState.empty(
          pageSize: filters.pageSize,
        ).copyWith(lastError: error);
      },
    );
  }

  Object _watchEntityFilter() {
    return switch (entityType) {
      EntityType.password => ref.watch(passwordsFilterProvider),
      EntityType.note => ref.watch(notesFilterProvider),
      EntityType.otp => ref.watch(otpsFilterProvider),
      EntityType.bankCard => ref.watch(bankCardsFilterProvider),
      EntityType.file => ref.watch(filesFilterProvider),
      EntityType.document => ref.watch(documentsFilterProvider),
      EntityType.contact => ref.watch(contactsFilterProvider),
      EntityType.apiKey => ref.watch(apiKeysFilterProvider),
      EntityType.sshKey => ref.watch(sshKeysFilterProvider),
      EntityType.certificate => ref.watch(certificatesFilterProvider),
      EntityType.cryptoWallet => ref.watch(cryptoWalletsFilterProvider),
      EntityType.wifi => ref.watch(wifisFilterProvider),
      EntityType.identity => ref.watch(identitiesFilterProvider),
      EntityType.licenseKey => ref.watch(licenseKeysFilterProvider),
      EntityType.recoveryCodes => ref.watch(recoveryCodesFilterProvider),
      EntityType.loyaltyCard => ref.watch(loyaltyCardsFilterProvider),
    };
  }

  Object _readEntityFilter() {
    return switch (entityType) {
      EntityType.password => ref.read(passwordsFilterProvider),
      EntityType.note => ref.read(notesFilterProvider),
      EntityType.otp => ref.read(otpsFilterProvider),
      EntityType.bankCard => ref.read(bankCardsFilterProvider),
      EntityType.file => ref.read(filesFilterProvider),
      EntityType.document => ref.read(documentsFilterProvider),
      EntityType.contact => ref.read(contactsFilterProvider),
      EntityType.apiKey => ref.read(apiKeysFilterProvider),
      EntityType.sshKey => ref.read(sshKeysFilterProvider),
      EntityType.certificate => ref.read(certificatesFilterProvider),
      EntityType.cryptoWallet => ref.read(cryptoWalletsFilterProvider),
      EntityType.wifi => ref.read(wifisFilterProvider),
      EntityType.identity => ref.read(identitiesFilterProvider),
      EntityType.licenseKey => ref.read(licenseKeysFilterProvider),
      EntityType.recoveryCodes => ref.read(recoveryCodesFilterProvider),
      EntityType.loyaltyCard => ref.read(loyaltyCardsFilterProvider),
    };
  }

  Future<AppError?> _applyItemMutation(
    BaseCardDto item, {
    BaseCardDto? optimisticValue,
    bool removeFromList = false,
    bool moveToFront = false,
    bool moveToEnd = false,
    required AsyncResultDart<bool, AppError> Function() operation,
  }) async {
    final current = state.value;
    if (current == null) return null;

    List<BaseCardDto> optimisticItems;
    if (removeFromList) {
      optimisticItems = current.items
          .where((candidate) => candidate.id != item.id)
          .toList();
    } else {
      optimisticItems = [...current.items];
      final index = optimisticItems.indexWhere(
        (candidate) => candidate.id == item.id,
      );
      if (index != -1) {
        final updatedItem = optimisticValue ?? optimisticItems[index];
        optimisticItems.removeAt(index);
        if (moveToFront) {
          optimisticItems.insert(0, updatedItem);
        } else if (moveToEnd) {
          optimisticItems.add(updatedItem);
        } else {
          optimisticItems.insert(index, updatedItem);
        }
      }
    }

    state = AsyncData(
      current.copyWith(
        items: optimisticItems,
        totalCount: removeFromList
            ? current.totalCount - 1
            : current.totalCount,
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

  Future<AppError?> _applyBulkMutation<T extends Object>(
    List<String> ids, {
    required AsyncResultDart<T, AppError> Function() operation,
  }) async {
    if (ids.isEmpty) return null;

    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(clearLastError: true));
    }

    AppError? error;
    final result = await operation();
    result.fold((_) {}, (failure) => error = failure);

    if (error != null) {
      if (current != null) {
        state = AsyncData(current.copyWith(lastError: error));
      }
      return error;
    }

    await refresh();
    return null;
  }
}
