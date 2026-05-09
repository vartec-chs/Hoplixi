part of '../../screens/dashboard_home_screen.dart';

void _dashboardHomeInitState(_DashboardHomeScreenState state) {
  state._scrollController = ScrollController()..addListener(state._onScroll);
}

void _dashboardHomeDispose(_DashboardHomeScreenState state) {
  state._loadMoreDebounce?.cancel();
  state._scrollController.dispose();
}

void _dashboardHomeDidUpdateWidget(
  _DashboardHomeScreenState state,
  DashboardHomeScreenOld oldWidget,
) {
  if (oldWidget.entityType != state.widget.entityType) {
    state._resetList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final items =
          state.ref
              .read(paginatedListProvider(state.widget.entityType))
              .value
              ?.items ??
          [];
      state._syncItems(items);
    });
  }
}

void _dashboardHomeOnScroll(_DashboardHomeScreenState state) {
  if (!state._scrollController.hasClients) {
    return;
  }

  final position = state._scrollController.position;
  if (position.pixels >=
      position.maxScrollExtent - _DashboardHomeScreenState._kScrollThreshold) {
    state._tryLoadMore();
  }
}

void _dashboardHomeTryLoadMore(_DashboardHomeScreenState state) {
  if (state._loadMoreDebounce?.isActive ?? false) {
    return;
  }

  state._loadMoreDebounce = Timer(const Duration(milliseconds: 100), () {
    final listState = state.ref
        .read(paginatedListProvider(state.widget.entityType))
        .value;
    if (listState != null &&
        !listState.isLoadingMore &&
        listState.hasMore &&
        !listState.isLoading) {
      state.ref
          .read(paginatedListProvider(state.widget.entityType).notifier)
          .loadMore();
    }
  });
}

void _dashboardHomeSyncItems(
  _DashboardHomeScreenState state,
  List<BaseCardDto> newItems,
) {
  if (!state.mounted) {
    return;
  }

  final dashboardAnimationsEnabled =
      state.ref.read(dashboardAnimationsEnabledProvider).value ?? true;

  if (!dashboardAnimationsEnabled) {
    state._replaceItemsWithoutAnimation(newItems);
    return;
  }

  final viewMode = state.ref.read(currentViewModeProvider);
  final listState = state._listKey.currentState;
  final gridState = state._gridKey.currentState;

  final animationReady = viewMode == ViewMode.list
      ? listState != null
      : gridState != null;

  if (!animationReady) {
    state._updateState(() => state._displayedItems = List.of(newItems));
    return;
  }

  if (!state._shouldAnimateItems(newItems)) {
    state._replaceItemsWithoutAnimation(newItems);
    return;
  }

  state._performDiff(newItems, viewMode, listState, gridState);
}

bool _dashboardHomeShouldAnimateItems(
  _DashboardHomeScreenState state,
  List<BaseCardDto> newItems,
) {
  final dashboardAnimationsEnabled =
      state.ref.read(dashboardAnimationsEnabledProvider).value ?? true;
  if (!dashboardAnimationsEnabled) {
    return false;
  }

  final totalItems = newItems.length > state._displayedItems.length
      ? newItems.length
      : state._displayedItems.length;
  final animatedItemsThreshold =
      state.ref.read(dashboardAnimatedItemsThresholdProvider).value ?? 15;
  return totalItems <= animatedItemsThreshold;
}

void _dashboardHomeReplaceItemsWithoutAnimation(
  _DashboardHomeScreenState state,
  List<BaseCardDto> newItems,
) {
  state._updateState(() {
    state._displayedItems = List.of(newItems);
    state._isClearing = false;
    state._listKey = GlobalKey<SliverAnimatedListState>();
    state._gridKey = GlobalKey<SliverAnimatedGridState>();
  });
}

void _dashboardHomePerformDiff(
  _DashboardHomeScreenState state,
  List<BaseCardDto> newItems,
  ViewMode viewMode,
  SliverAnimatedListState? listState,
  SliverAnimatedGridState? gridState,
) {
  final newIds = newItems.map((item) => item.id).toSet();
  var didMutate = false;

  for (var i = state._displayedItems.length - 1; i >= 0; i--) {
    final item = state._displayedItems[i];
    if (!newIds.contains(item.id)) {
      state._displayedItems.removeAt(i);
      didMutate = true;
      state._animateRemove(i, item, viewMode, listState, gridState);
    }
  }

  if (didMutate && newItems.isEmpty) {
    state._isClearing = true;
    Timer(kAnimationDuration, () {
      if (state.mounted) {
        state._updateState(() => state._isClearing = false);
      }
    });
  }

  final indexById = <String, int>{
    for (var i = 0; i < state._displayedItems.length; i++)
      state._displayedItems[i].id: i,
  };

  for (var i = 0; i < newItems.length; i++) {
    final newItem = newItems[i];
    final id = newItem.id;

    if (i < state._displayedItems.length && state._displayedItems[i].id == id) {
      if (state._displayedItems[i] != newItem) {
        state._displayedItems[i] = newItem;
        didMutate = true;
      }
      indexById[id] = i;
      continue;
    }

    final existingIndex = indexById[id];
    if (existingIndex != null && existingIndex >= i) {
      final moved = state._displayedItems.removeAt(existingIndex);
      state._animateRemove(
        existingIndex,
        moved,
        viewMode,
        listState,
        gridState,
      );
      state._displayedItems.insert(i, newItem);
      state._animateInsert(i, viewMode, listState, gridState);
      for (var j = i; j < state._displayedItems.length; j++) {
        indexById[state._displayedItems[j].id] = j;
      }
      didMutate = true;
    } else if (existingIndex == null) {
      state._displayedItems.insert(i, newItem);
      state._animateInsert(i, viewMode, listState, gridState);
      for (var j = i; j < state._displayedItems.length; j++) {
        indexById[state._displayedItems[j].id] = j;
      }
      didMutate = true;
    }
  }

  if (didMutate) {
    state._updateState(() {});
  }
}

void _dashboardHomeAnimateInsert(
  _DashboardHomeScreenState state,
  int index,
  ViewMode viewMode,
  SliverAnimatedListState? listState,
  SliverAnimatedGridState? gridState,
) {
  if (viewMode == ViewMode.list) {
    listState?.insertItem(index, duration: kAnimationDuration);
    return;
  }

  gridState?.insertItem(index, duration: kAnimationDuration);
}

void _dashboardHomeAnimateRemove(
  _DashboardHomeScreenState state,
  int index,
  BaseCardDto item,
  ViewMode viewMode,
  SliverAnimatedListState? listState,
  SliverAnimatedGridState? gridState,
) {
  Widget builder(BuildContext context, Animation<double> animation) {
    return DashboardHomeBuilders.buildRemovedItem(
      context: context,
      ref: state.ref,
      entityType: state.widget.entityType,
      item: item,
      animation: animation,
      viewMode: viewMode,
      callbacks: state._callbacks,
    );
  }

  if (viewMode == ViewMode.list) {
    listState?.removeItem(index, builder, duration: kAnimationDuration);
    return;
  }

  gridState?.removeItem(index, builder, duration: kAnimationDuration);
}

void _dashboardHomeRemoveItemLocally(
  _DashboardHomeScreenState state,
  String id,
) {
  state._updateState(() {
    state._displayedItems.removeWhere((item) => item.id == id);
    state._selectedIds.remove(id);
    if (state._selectedIds.isEmpty) {
      state._isBulkMode = false;
    }
  });
}

void _dashboardHomeResetList(_DashboardHomeScreenState state) {
  state._scrollToTopSafe();
  state._updateState(() {
    state._displayedItems = [];
    state._isClearing = false;
    state._isBulkMode = false;
    state._selectedIds.clear();
    state._listKey = GlobalKey<SliverAnimatedListState>();
    state._gridKey = GlobalKey<SliverAnimatedGridState>();
  });
}

void _dashboardHomeScrollToTopSafe(_DashboardHomeScreenState state) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!state.mounted || !state._scrollController.hasClients) {
      return;
    }

    final position = state._scrollController.position;
    if (position.hasContentDimensions && position.pixels != 0) {
      state._scrollController.jumpTo(0);
    }
  });
}
