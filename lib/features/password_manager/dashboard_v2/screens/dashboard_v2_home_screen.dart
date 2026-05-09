import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/routing/paths.dart';

import '../models/dashboard_entity_type.dart';
import '../models/dashboard_view_mode.dart';
import '../providers/dashboard_filter_provider.dart';
import '../providers/dashboard_list_controller.dart';
import '../providers/dashboard_selection_provider.dart';
import '../widgets/app_bar/app_bar.dart';
import '../widgets/dashboard_v2_bulk_bar.dart';
import '../widgets/dashboard_v2_error_banner.dart';
import '../widgets/dashboard_v2_items_view.dart';

final class DashboardV2HomeScreen extends ConsumerStatefulWidget {
  const DashboardV2HomeScreen({
    super.key,
    this.initialEntityType = DashboardEntityType.password,
    this.onOpenItem,
    this.onCreateItem,
  });

  final DashboardEntityType initialEntityType;
  final void Function(DashboardEntityType entityType, String id)? onOpenItem;
  final void Function(DashboardEntityType entityType)? onCreateItem;

  @override
  ConsumerState<DashboardV2HomeScreen> createState() =>
      _DashboardV2HomeScreenState();
}

final class _DashboardV2HomeScreenState
    extends ConsumerState<DashboardV2HomeScreen> {
  late DashboardEntityType _entityType;

  @override
  void initState() {
    super.initState();
    _entityType = widget.initialEntityType;
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(dashboardFilterProvider);
    final listState = ref.watch(dashboardListControllerProvider(_entityType));
    final selectedIds = ref.watch(dashboardSelectionProvider(_entityType));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 520) _loadMore();
          return false;
        },
        child: CustomScrollView(
          slivers: [
            DashboardV2SliverAppBar(
              entityType: _entityType,
              onEntityTypeChanged: _setEntityType,
              additionalActions: [_ViewModeAction(viewMode: filters.viewMode)],
              onFilterApplied: () => ref
                  .read(dashboardListControllerProvider(_entityType).notifier)
                  .refresh(),
            ),
            ...listState.when(
              loading: () => [_buildLoading()],
              error: (error, _) => [_buildFatalError(error)],
              data: (data) => [
                if (data.lastError != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    sliver: SliverToBoxAdapter(
                      child: DashboardV2ErrorBanner(
                        error: data.lastError!,
                        onRetry: () => ref
                            .read(
                              dashboardListControllerProvider(
                                _entityType,
                              ).notifier,
                            )
                            .refresh(),
                      ),
                    ),
                  ),
                if (selectedIds.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    sliver: SliverToBoxAdapter(
                      child: DashboardV2BulkBar(
                        selectedCount: selectedIds.length,
                        onClear: () => ref
                            .read(
                              dashboardSelectionProvider(_entityType).notifier,
                            )
                            .clear(),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  sliver: DashboardV2ItemsView(
                    items: data.items,
                    viewMode: filters.viewMode,
                    selectedIds: selectedIds,
                    onOpen: _openItem,
                    onToggleSelection: _toggleSelection,
                    onStartSelection: _startSelection,
                    onToggleFavorite: _toggleFavorite,
                    onTogglePinned: _togglePinned,
                    onToggleArchived: _toggleArchived,
                    onDelete: _deleteItem,
                    onRestore: _restoreItem,
                    onOpenView: _openViewItem,
                    onOpenHistory: (item) => context.push(
                      AppRoutesPaths.dashboardHistoryWithParams(
                        EntityType.values.firstWhere(
                          (e) => e.id == _entityType.id,
                        ),
                        item.id,
                      ),
                    ),
                  ),
                ),
                if (data.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: LinearProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildFatalError(Object error) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Dashboard v2 не смог загрузиться: $error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _setEntityType(DashboardEntityType entityType) {
    if (entityType == _entityType) return;
    ref.read(dashboardSelectionProvider(_entityType).notifier).clear();
    setState(() => _entityType = entityType);
  }

  void _loadMore() {
    ref.read(dashboardListControllerProvider(_entityType).notifier).loadMore();
  }

  void _openItem(BaseCardDto item) {
    widget.onOpenItem?.call(_entityType, item.id);
  }

  void _startSelection(String id) {
    ref.read(dashboardSelectionProvider(_entityType).notifier).selectOnly(id);
  }

  void _toggleSelection(String id) {
    ref.read(dashboardSelectionProvider(_entityType).notifier).toggle(id);
  }

  Future<void> _toggleFavorite(BaseCardDto item) async {
    await _showMutationErrorIfNeeded(
      await ref
          .read(dashboardListControllerProvider(_entityType).notifier)
          .toggleFavorite(item),
    );
  }

  Future<void> _togglePinned(BaseCardDto item) async {
    await _showMutationErrorIfNeeded(
      await ref
          .read(dashboardListControllerProvider(_entityType).notifier)
          .togglePinned(item),
    );
  }

  Future<void> _toggleArchived(BaseCardDto item) async {
    await _showMutationErrorIfNeeded(
      await ref
          .read(dashboardListControllerProvider(_entityType).notifier)
          .toggleArchived(item),
    );
  }

  Future<void> _deleteItem(BaseCardDto item) async {
    final controller = ref.read(
      dashboardListControllerProvider(_entityType).notifier,
    );
    await _showMutationErrorIfNeeded(
      await (item.isDeleted
          ? controller.permanentDelete(item)
          : controller.softDelete(item)),
    );
  }

  Future<void> _restoreItem(BaseCardDto item) async {
    await _showMutationErrorIfNeeded(
      await ref
          .read(dashboardListControllerProvider(_entityType).notifier)
          .restore(item),
    );
  }

  Future<void> _showMutationErrorIfNeeded(dynamic error) async {
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }

  void _openViewItem(BaseCardDto item) {
    final viewPath = AppRoutesPaths.dashboardEntityView(
      EntityType.values.firstWhere((e) => e.id == _entityType.id),
      item.id,
    );
    if (GoRouter.of(context).state.matchedLocation != viewPath) {
      context.push(viewPath);
    }
  }
}

final class _ViewModeAction extends ConsumerWidget {
  const _ViewModeAction({required this.viewMode});

  final DashboardViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGrid = viewMode.isGrid;

    return IconButton(
      tooltip: isGrid ? 'Показать списком' : 'Показать сеткой',
      icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
      onPressed: () {
        ref
            .read(dashboardFilterProvider.notifier)
            .setViewMode(
              isGrid ? DashboardViewMode.list : DashboardViewMode.grid,
            );
      },
    );
  }
}
