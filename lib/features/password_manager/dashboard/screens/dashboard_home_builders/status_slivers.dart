part of '../dashboard_home_builders.dart';

Widget _resolveDashboardStatusSliver({
  required BuildContext context,
  required AsyncValue<DashboardListState<BaseCardDto>> asyncValue,
  required EntityType entityType,
  required bool isClearing,
  required VoidCallback onRetry,
}) {
  if (isClearing) {
    return const SliverToBoxAdapter(
      key: ValueKey('clearing'),
      child: SizedBox.shrink(),
    );
  }

  if (asyncValue.isLoading) {
    return const SliverFillRemaining(
      key: ValueKey('loading'),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  if (asyncValue.hasError) {
    return _buildDashboardErrorSliver(
      context: context,
      error: asyncValue.error!,
      onRetry: onRetry,
      key: const ValueKey('error'),
    );
  }

  final providerItems = asyncValue.value?.items ?? [];
  if (providerItems.isEmpty) {
    return _buildDashboardEmptyState(
      context: context,
      entityType: entityType,
      key: const ValueKey('empty'),
    );
  }

  return const SliverToBoxAdapter(
    key: ValueKey('syncing'),
    child: SizedBox.shrink(),
  );
}

Widget _buildDashboardFooter({
  required bool hasMore,
  required bool isLoadingMore,
  required bool hasDisplayedItems,
  required BuildContext context,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final isSmallScreen = screenWidth <= 700;
  final smallScreenBottomInset =
      MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 24;

  if (isLoadingMore) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  if (!hasMore && hasDisplayedItems) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(
          top: isSmallScreen ? 8 : 20,
          bottom: isSmallScreen ? smallScreenBottomInset : 20,
        ),
        child: const Align(
          alignment: Alignment.topCenter,
          child: Text(
            'Больше нет данных',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  return const SliverToBoxAdapter(child: SizedBox(height: 8));
}

Widget _buildDashboardEmptyState({
  required BuildContext context,
  required EntityType entityType,
  Key? key,
}) {
  return SliverFillRemaining(
    key: key,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(entityType.icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Нет данных', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Добавьте первый элемент',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDashboardErrorSliver({
  required BuildContext context,
  required Object error,
  required VoidCallback onRetry,
  Key? key,
}) {
  return SliverFillRemaining(
    key: key,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Ошибка: $error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    ),
  );
}
