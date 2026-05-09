import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/dashboard_entity_type.dart';
import '../models/dashboard_filter_state.dart';
import '../providers/dashboard_filter_provider.dart';
import '../providers/dashboard_list_controller.dart';
import '../providers/dashboard_selection_provider.dart';
import '../widgets/dashboard_v2_bulk_bar.dart';
import '../widgets/dashboard_v2_error_banner.dart';
import '../widgets/dashboard_v2_items_view.dart';
import '../widgets/dashboard_v2_toolbar.dart';

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

final class _DashboardV2HomeScreenState extends ConsumerState<DashboardV2HomeScreen> {
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
      floatingActionButton: FloatingActionButton(
        tooltip: 'Создать',
        onPressed: () => widget.onCreateItem?.call(_entityType),
        child: const Icon(LucideIcons.plus),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: listState.when(
            loading: () => _buildLoading(filters),
            error: (error, _) => _buildFatalError(error),
            data: (data) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardV2Toolbar(
                    entityType: _entityType,
                    query: filters.query,
                    tab: filters.tab,
                    viewMode: filters.viewMode,
                    totalCount: data.totalCount,
                    onEntityTypeChanged: _setEntityType,
                    onQueryChanged: (value) => ref
                        .read(dashboardFilterProvider.notifier)
                        .setQuery(value),
                    onTabChanged: (value) => ref
                        .read(dashboardFilterProvider.notifier)
                        .setTab(value),
                    onViewModeChanged: (value) => ref
                        .read(dashboardFilterProvider.notifier)
                        .setViewMode(value),
                    onRefresh: () => ref
                        .read(dashboardListControllerProvider(_entityType).notifier)
                        .refresh(),
                  ),
                  if (data.lastError != null) ...[
                    const SizedBox(height: 12),
                    DashboardV2ErrorBanner(
                      error: data.lastError!,
                      onRetry: () => ref
                          .read(
                            dashboardListControllerProvider(_entityType).notifier,
                          )
                          .refresh(),
                    ),
                  ],
                  if (selectedIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DashboardV2BulkBar(
                      selectedCount: selectedIds.length,
                      onClear: () => ref
                          .read(dashboardSelectionProvider(_entityType).notifier)
                          .clear(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.extentAfter < 520) {
                          _loadMore();
                        }
                        return false;
                      },
                      child: DashboardV2ItemsView(
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
                      ),
                    ),
                  ),
                  if (data.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(DashboardFilterState filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardV2Toolbar(
          entityType: _entityType,
          query: filters.query,
          tab: filters.tab,
          viewMode: filters.viewMode,
          totalCount: 0,
          onEntityTypeChanged: _setEntityType,
          onQueryChanged: (value) =>
              ref.read(dashboardFilterProvider.notifier).setQuery(value),
          onTabChanged: (value) =>
              ref.read(dashboardFilterProvider.notifier).setTab(value),
          onViewModeChanged: (value) =>
              ref.read(dashboardFilterProvider.notifier).setViewMode(value),
          onRefresh: () {},
        ),
        const SizedBox(height: 24),
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildFatalError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Dashboard v2 не смог загрузиться: $error',
          textAlign: TextAlign.center,
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
    await _showMutationErrorIfNeeded(
      await ref
          .read(dashboardListControllerProvider(_entityType).notifier)
          .softDelete(item),
    );
  }

  Future<void> _showMutationErrorIfNeeded(dynamic error) async {
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  }
}
