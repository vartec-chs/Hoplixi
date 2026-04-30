part of 'dashboard_home_builders.dart';

Widget _buildDashboardAnimatedListOrGrid({
  required BuildContext context,
  required WidgetRef ref,
  required EntityType entityType,
  required ViewMode viewMode,
  required DashboardListState<BaseCardDto>? state,
  required List<BaseCardDto> displayedItems,
  required GlobalKey<SliverAnimatedListState> listKey,
  required GlobalKey<SliverAnimatedGridState> gridKey,
  required DashboardCardCallbacks callbacks,
  required bool isBulkMode,
  required Set<String> selectedIds,
  required void Function(String id) onItemTap,
  required void Function(String id) onItemLongPress,
  required void Function(String id) onOpenView,
  Key? key,
}) {
  final dashboardAnimationsEnabled =
      ref.watch(dashboardAnimationsEnabledProvider).value ?? true;
  final hasMore = state?.hasMore ?? false;
  final isLoadingMore = state?.isLoadingMore ?? false;
  final animatedItemsThreshold =
      ref.watch(dashboardAnimatedItemsThresholdProvider).value ?? 15;
  final useAnimatedSliver =
      dashboardAnimationsEnabled &&
      displayedItems.length <= animatedItemsThreshold;

  final listSliver = viewMode == ViewMode.list
      ? (useAnimatedSliver
            ? _buildDashboardSliverAnimatedList(
                listKey: listKey,
                displayedItems: displayedItems,
                context: context,
                ref: ref,
                entityType: entityType,
                viewMode: viewMode,
                callbacks: callbacks,
                isBulkMode: isBulkMode,
                selectedIds: selectedIds,
                onItemTap: onItemTap,
                onItemLongPress: onItemLongPress,
                onOpenView: onOpenView,
              )
            : _buildDashboardSliverList(
                displayedItems: displayedItems,
                context: context,
                ref: ref,
                entityType: entityType,
                viewMode: viewMode,
                callbacks: callbacks,
                isBulkMode: isBulkMode,
                selectedIds: selectedIds,
                onItemTap: onItemTap,
                onItemLongPress: onItemLongPress,
                onOpenView: onOpenView,
              ))
      : (useAnimatedSliver
            ? _buildDashboardSliverAnimatedGrid(
                gridKey: gridKey,
                displayedItems: displayedItems,
                context: context,
                ref: ref,
                entityType: entityType,
                viewMode: viewMode,
                callbacks: callbacks,
                isBulkMode: isBulkMode,
                selectedIds: selectedIds,
                onItemTap: onItemTap,
                onItemLongPress: onItemLongPress,
                onOpenView: onOpenView,
              )
            : _buildDashboardSliverGrid(
                displayedItems: displayedItems,
                context: context,
                ref: ref,
                entityType: entityType,
                viewMode: viewMode,
                callbacks: callbacks,
                isBulkMode: isBulkMode,
                selectedIds: selectedIds,
                onItemTap: onItemTap,
                onItemLongPress: onItemLongPress,
                onOpenView: onOpenView,
              ));

  return SliverMainAxisGroup(
    key: key,
    slivers: [
      listSliver,
      _buildDashboardFooter(
        hasMore: hasMore,
        isLoadingMore: isLoadingMore,
        hasDisplayedItems: displayedItems.isNotEmpty,
        context: context,
      ),
    ],
  );
}

Widget _buildDashboardSliverAnimatedList({
  required GlobalKey<SliverAnimatedListState> listKey,
  required List<BaseCardDto> displayedItems,
  required BuildContext context,
  required WidgetRef ref,
  required EntityType entityType,
  required ViewMode viewMode,
  required DashboardCardCallbacks callbacks,
  required bool isBulkMode,
  required Set<String> selectedIds,
  required void Function(String id) onItemTap,
  required void Function(String id) onItemLongPress,
  required void Function(String id) onOpenView,
}) {
  return SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    sliver: SliverAnimatedList(
      key: listKey,
      initialItemCount: displayedItems.length,
      itemBuilder: (ctx, index, animation) {
        if (index >= displayedItems.length) return const SizedBox.shrink();
        return _buildDashboardItemTransition(
          context: ctx,
          ref: ref,
          item: displayedItems[index],
          animation: animation,
          viewMode: viewMode,
          entityType: entityType,
          callbacks: callbacks,
          isBulkMode: isBulkMode,
          selectedIds: selectedIds,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
          onOpenView: onOpenView,
        );
      },
    ),
  );
}

Widget _buildDashboardSliverAnimatedGrid({
  required GlobalKey<SliverAnimatedGridState> gridKey,
  required List<BaseCardDto> displayedItems,
  required BuildContext context,
  required WidgetRef ref,
  required EntityType entityType,
  required ViewMode viewMode,
  required DashboardCardCallbacks callbacks,
  required bool isBulkMode,
  required Set<String> selectedIds,
  required void Function(String id) onItemTap,
  required void Function(String id) onItemLongPress,
  required void Function(String id) onOpenView,
}) {
  return SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    sliver: SliverAnimatedGrid(
      key: gridKey,
      initialItemCount: displayedItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (ctx, index, animation) {
        if (index >= displayedItems.length) return const SizedBox.shrink();
        return _buildDashboardItemTransition(
          context: ctx,
          ref: ref,
          item: displayedItems[index],
          animation: animation,
          viewMode: viewMode,
          entityType: entityType,
          callbacks: callbacks,
          isBulkMode: isBulkMode,
          selectedIds: selectedIds,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
          onOpenView: onOpenView,
        );
      },
    ),
  );
}

Widget _buildDashboardSliverList({
  required List<BaseCardDto> displayedItems,
  required BuildContext context,
  required WidgetRef ref,
  required EntityType entityType,
  required ViewMode viewMode,
  required DashboardCardCallbacks callbacks,
  required bool isBulkMode,
  required Set<String> selectedIds,
  required void Function(String id) onItemTap,
  required void Function(String id) onItemLongPress,
  required void Function(String id) onOpenView,
}) {
  return SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate((ctx, index) {
        if (index >= displayedItems.length) {
          return const SizedBox.shrink();
        }

        return _buildDashboardStaticItem(
          context: ctx,
          ref: ref,
          item: displayedItems[index],
          viewMode: viewMode,
          entityType: entityType,
          callbacks: callbacks,
          isBulkMode: isBulkMode,
          selectedIds: selectedIds,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
          onOpenView: onOpenView,
        );
      }, childCount: displayedItems.length),
    ),
  );
}

Widget _buildDashboardSliverGrid({
  required List<BaseCardDto> displayedItems,
  required BuildContext context,
  required WidgetRef ref,
  required EntityType entityType,
  required ViewMode viewMode,
  required DashboardCardCallbacks callbacks,
  required bool isBulkMode,
  required Set<String> selectedIds,
  required void Function(String id) onItemTap,
  required void Function(String id) onItemLongPress,
  required void Function(String id) onOpenView,
}) {
  return SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    sliver: SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      delegate: SliverChildBuilderDelegate((ctx, index) {
        if (index >= displayedItems.length) {
          return const SizedBox.shrink();
        }

        return _buildDashboardStaticItem(
          context: ctx,
          ref: ref,
          item: displayedItems[index],
          viewMode: viewMode,
          entityType: entityType,
          callbacks: callbacks,
          isBulkMode: isBulkMode,
          selectedIds: selectedIds,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
          onOpenView: onOpenView,
        );
      }, childCount: displayedItems.length),
    ),
  );
}
