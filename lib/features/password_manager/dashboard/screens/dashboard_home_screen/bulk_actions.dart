part of '../dashboard_home_screen.dart';

void _dashboardHomeOpenItemView(_DashboardHomeScreenState state, String id) {
  final viewPath = AppRoutesPaths.dashboardEntityView(
    state.widget.entityType,
    id,
  );
  if (GoRouter.of(state.context).state.matchedLocation != viewPath) {
    state.context.push(viewPath);
  }
}

void _dashboardHomeEnterBulkMode(_DashboardHomeScreenState state, String id) {
  state._updateState(() {
    state._isBulkMode = true;
    state._selectedIds.add(id);
  });
}

void _dashboardHomeToggleSelection(_DashboardHomeScreenState state, String id) {
  state._updateState(() {
    if (state._selectedIds.contains(id)) {
      state._selectedIds.remove(id);
    } else {
      state._selectedIds.add(id);
    }
    state._isBulkMode = state._selectedIds.isNotEmpty;
  });
}

void _dashboardHomeHandleItemLongPress(
  _DashboardHomeScreenState state,
  String id,
) {
  if (state._isBulkMode) {
    state._toggleSelection(id);
    return;
  }

  state._enterBulkMode(id);
}

void _dashboardHomeExitBulkMode(_DashboardHomeScreenState state) {
  if (!state._isBulkMode && state._selectedIds.isEmpty) {
    return;
  }

  state._updateState(() {
    state._isBulkMode = false;
    state._selectedIds.clear();
  });
}

void _dashboardHomePruneSelection(
  _DashboardHomeScreenState state,
  List<BaseCardDto> items,
) {
  if (state._selectedIds.isEmpty) {
    return;
  }

  final validIds = items.map((item) => item.id).toSet();
  final nextSelected = state._selectedIds.intersection(validIds);

  if (nextSelected.length == state._selectedIds.length) {
    return;
  }

  state._updateState(() {
    state._selectedIds
      ..clear()
      ..addAll(nextSelected);
    state._isBulkMode = state._selectedIds.isNotEmpty;
  });
}

Future<void> _dashboardHomeRunBulkAction(
  _DashboardHomeScreenState state, {
  required Future<void> Function(
    PaginatedListNotifier notifier,
    List<String> ids,
  )
  action,
  required String successTitle,
}) async {
  if (state._selectedIds.isEmpty || state._isApplyingBulkAction) {
    return;
  }

  final notifier = state.ref.read(
    paginatedListProvider(state.widget.entityType).notifier,
  );
  final selectedIds = state._selectedIds.toList(growable: false);

  state._updateState(() => state._isApplyingBulkAction = true);

  try {
    await action(notifier, selectedIds);
    if (!state.mounted) {
      return;
    }
    state._exitBulkMode();
    Toaster.success(title: successTitle);
  } catch (_) {
    if (!state.mounted) {
      return;
    }
    Toaster.error(title: 'Не удалось выполнить массовое действие');
  } finally {
    if (state.mounted) {
      state._updateState(() => state._isApplyingBulkAction = false);
    }
  }
}

Future<void> _dashboardHomeApplyBulkArchive(
  _DashboardHomeScreenState state,
) async {
  if (state._selectedIds.isEmpty || state._isApplyingBulkAction) {
    return;
  }

  final shouldArchive = state._shouldArchiveSelection;

  await state._runBulkAction(
    action: (notifier, ids) => notifier.bulkSetArchive(ids, shouldArchive),
    successTitle: shouldArchive
        ? 'Элементы перенесены в архив'
        : 'Элементы извлечены из архива',
  );
}

Future<void> _dashboardHomeApplyBulkFavorite(
  _DashboardHomeScreenState state,
) async {
  if (state._selectedIds.isEmpty || state._isApplyingBulkAction) {
    return;
  }

  final shouldFavorite = state._shouldFavoriteSelection;

  await state._runBulkAction(
    action: (notifier, ids) => notifier.bulkSetFavorite(ids, shouldFavorite),
    successTitle: shouldFavorite
        ? 'Элементы добавлены в избранное'
        : 'Элементы удалены из избранного',
  );
}

Future<void> _dashboardHomeApplyBulkPin(_DashboardHomeScreenState state) async {
  if (state._selectedIds.isEmpty || state._isApplyingBulkAction) {
    return;
  }

  final shouldPin = state._shouldPinSelection;

  await state._runBulkAction(
    action: (notifier, ids) => notifier.bulkSetPin(ids, shouldPin),
    successTitle: shouldPin ? 'Элементы закреплены' : 'Элементы откреплены',
  );
}
