part of 'dashboard_home_builders.dart';

Widget _buildDashboardItemTransition({
  required BuildContext context,
  required WidgetRef ref,
  required BaseCardDto item,
  required Animation<double> animation,
  required ViewMode viewMode,
  required EntityType entityType,
  required DashboardCardCallbacks callbacks,
  required bool isBulkMode,
  required Set<String> selectedIds,
  required void Function(String id) onItemTap,
  required void Function(String id) onItemLongPress,
  required void Function(String id) onOpenView,
}) {
  final card = viewMode == ViewMode.list
      ? _buildDashboardListCardFor(
          context: context,
          ref: ref,
          type: entityType,
          item: item,
          callbacks: callbacks,
          isBulkMode: isBulkMode,
          isSelected: selectedIds.contains(item.id),
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
          onOpenView: onOpenView,
        )
      : _buildDashboardGridCardFor(
          context: context,
          ref: ref,
          type: entityType,
          item: item,
          callbacks: callbacks,
          isBulkMode: isBulkMode,
          isSelected: selectedIds.contains(item.id),
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
          onOpenView: onOpenView,
        );

  return FadeScaleTransition(
    animation: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: card,
      ),
    ),
  );
}

Widget _buildDashboardStaticItem({
  required BuildContext context,
  required WidgetRef ref,
  required BaseCardDto item,
  required ViewMode viewMode,
  required EntityType entityType,
  required DashboardCardCallbacks callbacks,
  required bool isBulkMode,
  required Set<String> selectedIds,
  required void Function(String id) onItemTap,
  required void Function(String id) onItemLongPress,
  required void Function(String id) onOpenView,
}) {
  final card = viewMode == ViewMode.list
      ? _buildDashboardListCardFor(
          context: context,
          ref: ref,
          type: entityType,
          item: item,
          callbacks: callbacks,
          isBulkMode: isBulkMode,
          isSelected: selectedIds.contains(item.id),
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
          onOpenView: onOpenView,
        )
      : _buildDashboardGridCardFor(
          context: context,
          ref: ref,
          type: entityType,
          item: item,
          callbacks: callbacks,
          isBulkMode: isBulkMode,
          isSelected: selectedIds.contains(item.id),
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
          onOpenView: onOpenView,
        );

  return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: card);
}

Widget _buildDashboardRemovedItem({
  required BuildContext context,
  required WidgetRef ref,
  required EntityType entityType,
  required BaseCardDto item,
  required Animation<double> animation,
  required ViewMode viewMode,
  required DashboardCardCallbacks callbacks,
}) {
  final card = viewMode == ViewMode.list
      ? _buildDashboardListCardFor(
          context: context,
          ref: ref,
          type: entityType,
          item: item,
          callbacks: callbacks,
          isBulkMode: false,
          isSelected: false,
          onItemTap: (_) {},
          onItemLongPress: (_) {},
          onOpenView: (_) {},
          isDismissible: false,
        )
      : _buildDashboardGridCardFor(
          context: context,
          ref: ref,
          type: entityType,
          item: item,
          callbacks: callbacks,
          isBulkMode: false,
          isSelected: false,
          onItemTap: (_) {},
          onItemLongPress: (_) {},
          onOpenView: (_) {},
        );

  return FadeTransition(
    opacity: animation,
    child: SizeTransition(sizeFactor: animation, child: card),
  );
}

Widget _wrapDashboardInteractiveCard({
  required BuildContext context,
  required Widget child,
  required String itemId,
  required bool isBulkMode,
  required bool isSelected,
  required void Function(String id) onItemTap,
  required void Function(String id) onItemLongPress,
}) {
  final radius = BorderRadius.circular(16);
  final theme = Theme.of(context);

  if (isBulkMode) {
    return Stack(
      children: [
        IgnorePointer(ignoring: true, child: child),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: () => onItemTap(itemId),
              onLongPress: () => onItemLongPress(itemId),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: kStatusSwitchDuration,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.25),
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: kStatusSwitchDuration,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.circle_outlined,
                size: 14,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  return GestureDetector(
    onLongPress: () => onItemLongPress(itemId),
    child: child,
  );
}
