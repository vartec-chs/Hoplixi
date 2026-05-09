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
import 'filter_providers/filter_providers.dart';

final dashboardListControllerProvider = AsyncNotifierProvider.autoDispose
    .family<DashboardListController, DashboardListState, DashboardEntityType>(
      DashboardListController.new,
    );

final class DashboardListController extends AsyncNotifier<DashboardListState> {
  DashboardListController(this.entityType);

  static const _logTag = 'DashboardV2ListController';

  final DashboardEntityType entityType;

  @override
  Future<DashboardListState> build() async {
    final filters = ref.watch(dashboardFilterProvider);
    final entityFilter = _watchEntityFilter();
    return _loadFirstPage(filters, entityFilter);
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
    return _applyItemMutation(
      item,
      optimisticValue: item.copyWithBase(isFavorite: !item.isFavorite),
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .setFavorite(
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
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .setPinned(
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
      operation: () => ref
          .read(dashboardRepositoryProvider)
          .setArchived(
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
      DashboardEntityType.password => ref.watch(passwordsFilterProvider),
      DashboardEntityType.note => ref.watch(notesFilterProvider),
      DashboardEntityType.otp => ref.watch(otpsFilterProvider),
      DashboardEntityType.bankCard => ref.watch(bankCardsFilterProvider),
      DashboardEntityType.file => ref.watch(filesFilterProvider),
      DashboardEntityType.document => ref.watch(documentsFilterProvider),
      DashboardEntityType.contact => ref.watch(contactsFilterProvider),
      DashboardEntityType.apiKey => ref.watch(apiKeysFilterProvider),
      DashboardEntityType.sshKey => ref.watch(sshKeysFilterProvider),
      DashboardEntityType.certificate => ref.watch(certificatesFilterProvider),
      DashboardEntityType.cryptoWallet => ref.watch(
        cryptoWalletsFilterProvider,
      ),
      DashboardEntityType.wifi => ref.watch(wifisFilterProvider),
      DashboardEntityType.identity => ref.watch(identitiesFilterProvider),
      DashboardEntityType.licenseKey => ref.watch(licenseKeysFilterProvider),
      DashboardEntityType.recoveryCodes => ref.watch(
        recoveryCodesFilterProvider,
      ),
      DashboardEntityType.loyaltyCard => ref.watch(loyaltyCardsFilterProvider),
    };
  }

  Object _readEntityFilter() {
    return switch (entityType) {
      DashboardEntityType.password => ref.read(passwordsFilterProvider),
      DashboardEntityType.note => ref.read(notesFilterProvider),
      DashboardEntityType.otp => ref.read(otpsFilterProvider),
      DashboardEntityType.bankCard => ref.read(bankCardsFilterProvider),
      DashboardEntityType.file => ref.read(filesFilterProvider),
      DashboardEntityType.document => ref.read(documentsFilterProvider),
      DashboardEntityType.contact => ref.read(contactsFilterProvider),
      DashboardEntityType.apiKey => ref.read(apiKeysFilterProvider),
      DashboardEntityType.sshKey => ref.read(sshKeysFilterProvider),
      DashboardEntityType.certificate => ref.read(certificatesFilterProvider),
      DashboardEntityType.cryptoWallet => ref.read(cryptoWalletsFilterProvider),
      DashboardEntityType.wifi => ref.read(wifisFilterProvider),
      DashboardEntityType.identity => ref.read(identitiesFilterProvider),
      DashboardEntityType.licenseKey => ref.read(licenseKeysFilterProvider),
      DashboardEntityType.recoveryCodes => ref.read(
        recoveryCodesFilterProvider,
      ),
      DashboardEntityType.loyaltyCard => ref.read(loyaltyCardsFilterProvider),
    };
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
              if (candidate.id == item.id)
                optimisticValue ?? candidate
              else
                candidate,
          ];

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
}
