import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard_layout/dashboard_drawer_scope.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/widgets/category_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/widgets/tag_picker_field.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/core/models/enums/index.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

import '../models/dashboard_view_mode.dart';
import '../models/entity_type.dart';
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
    this.initialEntityType = EntityType.password,
    this.onOpenItem,
    this.onCreateItem,
  });

  final EntityType initialEntityType;
  final void Function(EntityType entityType, String id)? onOpenItem;
  final void Function(EntityType entityType)? onCreateItem;

  @override
  ConsumerState<DashboardV2HomeScreen> createState() =>
      _DashboardV2HomeScreenState();
}

final class _DashboardV2HomeScreenState
    extends ConsumerState<DashboardV2HomeScreen> {
  late EntityType _entityType;
  bool _isApplyingBulkAction = false;

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
    final drawerScope = DashboardDrawerScope.of(context);

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
              onMenuPressed: drawerScope?.openDrawer,

              onFilterApplied: () => ref
                  .read(dashboardListControllerProvider(_entityType).notifier)
                  .refresh(),
            ),
            ...listState.when(
              loading: () => [_buildLoading()],
              error: (error, _) => [_buildFatalError(error)],
              data: (data) {
                final selectedItems = data.items
                    .where((item) => selectedIds.contains(item.id))
                    .toList(growable: false);
                final shouldFavorite = selectedItems.any(
                  (item) => !item.isFavorite,
                );
                final shouldPin = selectedItems.any((item) => !item.isPinned);
                final shouldArchive = selectedItems.any(
                  (item) => !item.isArchived,
                );

                return [
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
                          onClear: _clearSelection,
                          onBulkDelete: _isApplyingBulkAction
                              ? null
                              : () => _showBulkDeleteDialog(selectedItems),
                          onBulkFavorite: _isApplyingBulkAction
                              ? null
                              : () => _applyBulkFavorite(shouldFavorite),
                          bulkFavoriteLabel: shouldFavorite
                              ? 'В избранное'
                              : 'Убрать из избранного',
                          onBulkPin: _isApplyingBulkAction
                              ? null
                              : () => _applyBulkPin(shouldPin),
                          bulkPinLabel: shouldPin ? 'Закрепить' : 'Открепить',
                          onBulkArchive: _isApplyingBulkAction
                              ? null
                              : () => _applyBulkArchive(shouldArchive),
                          bulkArchiveLabel: shouldArchive
                              ? 'В архив'
                              : 'Из архива',
                          onBulkAssignCategory: _isApplyingBulkAction
                              ? null
                              : _showBulkAssignCategoryDialog,
                          onBulkAssignTags: _isApplyingBulkAction
                              ? null
                              : _showBulkAssignTagsDialog,
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
                      onOpenEdit: _openEditItem,
                      onToggleSelection: _toggleSelection,
                      onStartSelection: _startSelection,
                      onToggleFavorite: _toggleFavorite,
                      onTogglePinned: _togglePinned,
                      onToggleArchived: _toggleArchived,
                      onDelete: _deleteItem,
                      onRestore: _restoreItem,
                      onOpenView: _openViewItem,
                      onOpenHistory: _openHistoryItem,
                    ),
                  ),
                  if (data.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: LinearProgressIndicator(),
                      ),
                    ),
                ];
              },
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

  void _setEntityType(EntityType entityType) {
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

  void _openEditItem(BaseCardDto item) {
    final editPath = AppRoutesPaths.dashboardEntityEdit(_entityType, item.id);
    if (GoRouter.of(context).state.matchedLocation != editPath) {
      context.push(editPath);
    }
  }

  void _startSelection(String id) {
    ref.read(dashboardSelectionProvider(_entityType).notifier).selectOnly(id);
  }

  void _toggleSelection(String id) {
    ref.read(dashboardSelectionProvider(_entityType).notifier).toggle(id);
  }

  void _clearSelection() {
    ref.read(dashboardSelectionProvider(_entityType).notifier).clear();
  }

  EntityType get _legacyEntityType =>
      EntityType.values.firstWhere((type) => type.id == _entityType.id);

  Future<void> _applyBulkArchive(bool shouldArchive) async {
    await _runBulkAction(
      action: (controller, ids) =>
          controller.bulkSetArchived(ids, shouldArchive),
      successTitle: shouldArchive
          ? 'Элементы перенесены в архив'
          : 'Элементы извлечены из архива',
    );
  }

  Future<void> _applyBulkFavorite(bool shouldFavorite) async {
    await _runBulkAction(
      action: (controller, ids) =>
          controller.bulkSetFavorite(ids, shouldFavorite),
      successTitle: shouldFavorite
          ? 'Элементы добавлены в избранное'
          : 'Элементы удалены из избранного',
    );
  }

  Future<void> _applyBulkPin(bool shouldPin) async {
    await _runBulkAction(
      action: (controller, ids) => controller.bulkSetPinned(ids, shouldPin),
      successTitle: shouldPin ? 'Элементы закреплены' : 'Элементы откреплены',
    );
  }

  Future<void> _showBulkDeleteDialog(List<BaseCardDto> selectedItems) async {
    final selectedIds = ref
        .read(dashboardSelectionProvider(_entityType))
        .toList(growable: false);
    if (selectedIds.isEmpty || _isApplyingBulkAction) return;

    final isPermanentDelete =
        selectedItems.isNotEmpty &&
        selectedItems.every((item) => item.isDeleted);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isPermanentDelete ? 'Удалить навсегда?' : 'Удалить элементы?',
          ),
          content: Text(
            isPermanentDelete
                ? 'Будет безвозвратно удалено элементов: ${selectedIds.length}.'
                : 'Будет перемещено в удалённые элементов: ${selectedIds.length}.',
          ),
          actions: [
            SmoothButton(
              type: SmoothButtonType.text,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              label: 'Отмена',
            ),
            SmoothButton(
              variant: SmoothButtonVariant.error,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              label: isPermanentDelete ? 'Удалить навсегда' : 'Удалить',
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await _runBulkAction(
      action: (controller, ids) =>
          controller.bulkDelete(ids, permanently: isPermanentDelete),
      successTitle: isPermanentDelete
          ? 'Элементы удалены навсегда'
          : 'Элементы перемещены в удалённые',
    );
  }

  Future<void> _showBulkAssignCategoryDialog() async {
    if (ref.read(dashboardSelectionProvider(_entityType)).isEmpty ||
        _isApplyingBulkAction) {
      return;
    }

    String? selectedCategoryId;
    String? selectedCategoryName;
    final legacyType = _legacyEntityType;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Назначить категорию'),
              content: SizedBox(
                height: 54,
                child: CategoryPickerField(
                  selectedCategoryId: selectedCategoryId,
                  selectedCategoryName: selectedCategoryName,
                  filterByType: [
                    legacyType.toCategoryType(),
                    CategoryType.mixed,
                  ],
                  onCategorySelected: (categoryId, categoryName) {
                    setDialogState(() {
                      selectedCategoryId = categoryId;
                      selectedCategoryName = categoryName;
                    });
                  },
                ),
              ),
              actions: [
                SmoothButton(
                  type: SmoothButtonType.text,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  label: 'Отмена',
                ),
                SmoothButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  label: 'Применить',
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    await _runBulkAction(
      action: (controller, ids) =>
          controller.bulkAssignCategory(ids, selectedCategoryId),
      successTitle: selectedCategoryId == null
          ? 'Категория очищена'
          : 'Категория назначена',
    );
  }

  Future<void> _showBulkAssignTagsDialog() async {
    if (ref.read(dashboardSelectionProvider(_entityType)).isEmpty ||
        _isApplyingBulkAction) {
      return;
    }

    var selectedTagIds = <String>[];
    var selectedTagNames = <String>[];
    final legacyType = _legacyEntityType;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Назначить теги'),
              content: SizedBox(
                height: 54,
                child: TagPickerField(
                  selectedTagIds: selectedTagIds,
                  selectedTagNames: selectedTagNames,
                  filterByType: [legacyType.toTagType(), TagType.mixed],
                  onTagsSelected: (tagIds, tagNames) {
                    setDialogState(() {
                      selectedTagIds = List<String>.from(tagIds);
                      selectedTagNames = List<String>.from(tagNames);
                    });
                  },
                ),
              ),
              actions: [
                SmoothButton(
                  type: SmoothButtonType.text,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  label: 'Отмена',
                ),
                SmoothButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  label: 'Применить',
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    await _runBulkAction(
      action: (controller, ids) =>
          controller.bulkAssignTags(ids, selectedTagIds),
      successTitle: selectedTagIds.isEmpty ? 'Теги очищены' : 'Теги обновлены',
    );
  }

  Future<void> _runBulkAction({
    required Future<Object?> Function(
      DashboardListController controller,
      List<String> ids,
    )
    action,
    required String successTitle,
  }) async {
    final selectedIds = ref
        .read(dashboardSelectionProvider(_entityType))
        .toList(growable: false);
    if (selectedIds.isEmpty || _isApplyingBulkAction) return;

    setState(() => _isApplyingBulkAction = true);

    try {
      final error = await action(
        ref.read(dashboardListControllerProvider(_entityType).notifier),
        selectedIds,
      );

      if (!mounted) return;

      if (error != null) {
        Toaster.error(
          title: 'Не удалось выполнить массовое действие',
          description: error.toString(),
        );
        return;
      }

      _clearSelection();
      Toaster.success(title: successTitle);
    } finally {
      if (mounted) {
        setState(() => _isApplyingBulkAction = false);
      }
    }
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
    Toaster.error(
      title: 'Не удалось выполнить действие',
      description: error.toString(),
    );
  }

  void _openHistoryItem(BaseCardDto item) {
    final historyPath = AppRoutesPaths.dashboardHistoryWithParams(
      EntityType.values.firstWhere((e) => e.id == _entityType.id),
      item.id,
    );
    if (GoRouter.of(context).state.matchedLocation != historyPath) {
      context.push(historyPath);
    }
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
