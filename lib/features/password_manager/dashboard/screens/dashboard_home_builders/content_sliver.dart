part of '../dashboard_home_builders.dart';

Widget _buildDashboardContentSliver({
  required BuildContext context,
  required WidgetRef ref,
  required EntityType entityType,
  required ViewMode viewMode,
  required AsyncValue<DashboardListState<BaseCardDto>> asyncValue,
  required List<BaseCardDto> displayedItems,
  required bool isClearing,
  required GlobalKey<SliverAnimatedListState> listKey,
  required GlobalKey<SliverAnimatedGridState> gridKey,
  required DashboardCardCallbacks callbacks,
  required bool isBulkMode,
  required Set<String> selectedIds,
  required void Function(String id) onItemTap,
  required void Function(String id) onItemLongPress,
  required void Function(String id) onOpenView,
  required VoidCallback onInvalidate,
}) {
  final hasDisplayedItems = displayedItems.isNotEmpty;

  if (hasDisplayedItems) {
    return _buildDashboardAnimatedListOrGrid(
      context: context,
      ref: ref,
      entityType: entityType,
      viewMode: viewMode,
      state: asyncValue.value,
      displayedItems: displayedItems,
      listKey: listKey,
      gridKey: gridKey,
      callbacks: callbacks,
      isBulkMode: isBulkMode,
      selectedIds: selectedIds,
      onItemTap: onItemTap,
      onItemLongPress: onItemLongPress,
      onOpenView: onOpenView,
    );
  }

  final statusSliver = _resolveDashboardStatusSliver(
    context: context,
    asyncValue: asyncValue,
    entityType: entityType,
    isClearing: isClearing,
    onRetry: onInvalidate,
  );

  return SliverMainAxisGroup(
    slivers: [
      _buildDashboardAnimatedListOrGrid(
        context: context,
        ref: ref,
        entityType: entityType,
        viewMode: viewMode,
        state: asyncValue.value,
        displayedItems: displayedItems,
        listKey: listKey,
        gridKey: gridKey,
        callbacks: callbacks,
        isBulkMode: isBulkMode,
        selectedIds: selectedIds,
        onItemTap: onItemTap,
        onItemLongPress: onItemLongPress,
        onOpenView: onOpenView,
      ),
      SliverAnimatedSwitcher(
        duration: kStatusSwitchDuration,
        child: statusSliver,
      ),
    ],
  );
}
