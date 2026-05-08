part of '../../screens/dashboard_home_screen.dart';

Widget _buildDashboardHomeScreen(
  _DashboardHomeScreenState state,
  BuildContext context,
) {
  final viewMode = state.ref.watch(currentViewModeProvider);
  final asyncValue = state.ref.watch(
    paginatedListProvider(state.widget.entityType),
  );

  Future.microtask(() {
    state.ref
        .read(baseFilterProvider.notifier)
        .setEntityType(state.widget.entityType.id);
  });

  final disableAppBarMenu = MediaQuery.of(context).size.width <= 700;

  _handleDashboardHomeInitialSync(state, asyncValue);
  _listenDashboardHomeListChanges(state);
  _listenDashboardHomeViewModeChanges(state, asyncValue);

  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        if (state._isBulkMode) {
          state._exitBulkMode();
          return;
        }
        state._showCloseDatabaseDialog();
      }
    },
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => state.ref
            .read(paginatedListProvider(state.widget.entityType).notifier)
            .refresh(),
        child: CustomScrollView(
          controller: state._scrollController,
          slivers: [
            DashboardSliverAppBar(
              entityType: state.widget.entityType,
              expandedHeight: 176.0,
              collapsedHeight: 60.0,
              pinned: true,
              floating: false,
              snap: false,
              showEntityTypeSelector: true,
              onMenuPressed: !disableAppBarMenu
                  ? null
                  : () {
                      final scope = DashboardDrawerScope.of(context);
                      if (scope != null) {
                        scope.openDrawer();
                      } else {
                        Scaffold.of(context).openDrawer();
                      }
                    },
            ),
            SliverToBoxAdapter(
              child: DashboardListToolBar(
                entityType: state.widget.entityType,
                viewMode: viewMode,
                listState: asyncValue,
                isBulkMode: state._isBulkMode,
                selectedCount: state._selectedIds.length,
                onExitBulkMode: state._isApplyingBulkAction
                    ? null
                    : state._exitBulkMode,
                onBulkDelete: state._isApplyingBulkAction
                    ? null
                    : state._showBulkDeleteDialog,
                onBulkFavorite: state._isApplyingBulkAction
                    ? null
                    : state._applyBulkFavorite,
                bulkFavoriteLabel: state._shouldFavoriteSelection
                    ? 'В избранное'
                    : 'Убрать из избранного',
                onBulkPin: state._isApplyingBulkAction
                    ? null
                    : state._applyBulkPin,
                bulkPinLabel: state._shouldPinSelection
                    ? 'Закрепить'
                    : 'Открепить',
                onBulkArchive: state._isApplyingBulkAction
                    ? null
                    : state._applyBulkArchive,
                bulkArchiveLabel: state._shouldArchiveSelection
                    ? 'В архив'
                    : 'Из архива',
                onBulkAssignCategory: state._isApplyingBulkAction
                    ? null
                    : state._showBulkAssignCategoryDialog,
                onBulkAssignTags: state._isApplyingBulkAction
                    ? null
                    : state._showBulkAssignTagsDialog,
              ),
            ),
            state._buildContentSliver(asyncValue, viewMode),
          ],
        ),
      ),
    ),
  );
}

void _handleDashboardHomeInitialSync(
  _DashboardHomeScreenState state,
  AsyncValue<DashboardListState<BaseCardDto>> asyncValue,
) {
  if (!state._isFirstBuild) {
    return;
  }

  state._isFirstBuild = false;
  asyncValue.whenData((listState) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mounted &&
          state._displayedItems.isEmpty &&
          listState.items.isNotEmpty) {
        state._syncItems(listState.items);
      }
    });
  });
}

void _listenDashboardHomeListChanges(_DashboardHomeScreenState state) {
  state.ref.listen<AsyncValue<DashboardListState<BaseCardDto>>>(
    paginatedListProvider(state.widget.entityType),
    (prev, next) {
      next.whenData((listState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state._syncItems(listState.items);
          state._pruneSelection(listState.items);
        });
      });
    },
  );
}

void _listenDashboardHomeViewModeChanges(
  _DashboardHomeScreenState state,
  AsyncValue<DashboardListState<BaseCardDto>> asyncValue,
) {
  state.ref.listen<ViewMode>(currentViewModeProvider, (prev, next) {
    if (prev != null && prev != next) {
      state._resetList();
      final items = asyncValue.value?.items ?? [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state._syncItems(items);
      });
    }
  });
}

Widget _buildDashboardHomeContentSliver(
  _DashboardHomeScreenState state,
  AsyncValue<DashboardListState<BaseCardDto>> asyncValue,
  ViewMode viewMode,
) {
  return DashboardHomeBuilders.buildContentSliver(
    context: state.context,
    ref: state.ref,
    entityType: state.widget.entityType,
    viewMode: viewMode,
    asyncValue: asyncValue,
    displayedItems: state._displayedItems,
    isClearing: state._isClearing,
    listKey: state._listKey,
    gridKey: state._gridKey,
    callbacks: state._callbacks,
    isBulkMode: state._isBulkMode,
    selectedIds: state._selectedIds,
    onItemTap: state._toggleSelection,
    onItemLongPress: state._handleItemLongPress,
    onOpenView: state._openItemView,
    onInvalidate: () =>
        state.ref.invalidate(paginatedListProvider(state.widget.entityType)),
  );
}
