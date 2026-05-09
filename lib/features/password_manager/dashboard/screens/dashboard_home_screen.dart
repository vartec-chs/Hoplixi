import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/base_filter_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/list_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home_screen_ui_builders/builders/dashboard_home_builders.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/app_bar/app_bar_widgets.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_list_toolbar.dart';
import 'package:hoplixi/features/password_manager/dashboard_layout/dashboard_drawer_scope.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/widgets/category_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/widgets/tag_picker_field.dart';
import 'package:hoplixi/features/settings/providers/settings_prefs_providers.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/core/models/enums/index.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

part '../widgets/dashboard_home_screen_ui_builders/build_helpers.dart';
part '../widgets/dashboard_home_screen_ui_builders/bulk_actions.dart';
part '../widgets/dashboard_home_screen_ui_builders/dialogs.dart';
part '../widgets/dashboard_home_screen_ui_builders/list_sync.dart';

/// Длительность анимации для элементов списка.
const kAnimationDuration = Duration(milliseconds: 180);

/// Экран дашборда со списком карточек.
///
/// Использует [SliverAnimatedList]/[SliverAnimatedGrid] для анимированного
/// отображения элементов с поддержкой diff-обновлений.
class DashboardHomeScreenOld extends ConsumerStatefulWidget {
  const DashboardHomeScreenOld({super.key, required this.entityType});

  final EntityType entityType;

  @override
  ConsumerState<DashboardHomeScreenOld> createState() =>
      _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends ConsumerState<DashboardHomeScreenOld> {
  static const _kScrollThreshold = 200.0;

  late final ScrollController _scrollController;
  Timer? _loadMoreDebounce;

  /// Ключи для анимированных списков — пересоздаются при сбросе.
  GlobalKey<SliverAnimatedListState> _listKey = GlobalKey();
  GlobalKey<SliverAnimatedGridState> _gridKey = GlobalKey();

  /// Локальный список для отображения (синхронизируется с провайдером).
  List<BaseCardDto> _displayedItems = [];

  /// Флаг очистки списка (для анимации пустого состояния).
  bool _isClearing = false;
  bool _isScrolled = false;

  /// Флаг первого построения — для начальной синхронизации.
  bool _isFirstBuild = true;

  /// Режим массового выбора элементов.
  bool _isBulkMode = false;

  /// Идентификаторы выбранных элементов.
  final Set<String> _selectedIds = <String>{};

  /// Защита от повторных bulk-операций.
  bool _isApplyingBulkAction = false;

  @override
  void initState() {
    super.initState();
    _dashboardHomeInitState(this);
  }

  @override
  void dispose() {
    _dashboardHomeDispose(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DashboardHomeScreenOld oldWidget) {
    super.didUpdateWidget(oldWidget);
    _dashboardHomeDidUpdateWidget(this, oldWidget);
  }

  DashboardCardCallbacks get _callbacks =>
      DashboardCardCallbacks.fromRefWithLocalRemove(
        ref,
        widget.entityType,
        _removeItemLocally,
      );

  List<BaseCardDto> get _selectedItems => _displayedItems
      .where((item) => _selectedIds.contains(item.id))
      .toList(growable: false);

  bool get _shouldArchiveSelection =>
      _selectedItems.any((item) => !item.isArchived);

  bool get _shouldFavoriteSelection =>
      _selectedItems.any((item) => !item.isFavorite);

  bool get _shouldPinSelection => _selectedItems.any((item) => !item.isPinned);

  void _updateState(VoidCallback fn) => setState(fn);

  void _onScroll() => _dashboardHomeOnScroll(this);

  void _tryLoadMore() => _dashboardHomeTryLoadMore(this);

  void _syncItems(List<BaseCardDto> newItems) =>
      _dashboardHomeSyncItems(this, newItems);

  bool _shouldAnimateItems(List<BaseCardDto> newItems) =>
      _dashboardHomeShouldAnimateItems(this, newItems);

  void _replaceItemsWithoutAnimation(List<BaseCardDto> newItems) =>
      _dashboardHomeReplaceItemsWithoutAnimation(this, newItems);

  void _performDiff(
    List<BaseCardDto> newItems,
    ViewMode viewMode,
    SliverAnimatedListState? listState,
    SliverAnimatedGridState? gridState,
  ) =>
      _dashboardHomePerformDiff(this, newItems, viewMode, listState, gridState);

  void _animateInsert(
    int index,
    ViewMode viewMode,
    SliverAnimatedListState? listState,
    SliverAnimatedGridState? gridState,
  ) => _dashboardHomeAnimateInsert(this, index, viewMode, listState, gridState);

  void _animateRemove(
    int index,
    BaseCardDto item,
    ViewMode viewMode,
    SliverAnimatedListState? listState,
    SliverAnimatedGridState? gridState,
  ) => _dashboardHomeAnimateRemove(
    this,
    index,
    item,
    viewMode,
    listState,
    gridState,
  );

  void _removeItemLocally(String id) =>
      _dashboardHomeRemoveItemLocally(this, id);

  void _resetList() => _dashboardHomeResetList(this);

  void _scrollToTopSafe() => _dashboardHomeScrollToTopSafe(this);

  void _openItemView(String id) => _dashboardHomeOpenItemView(this, id);

  void _enterBulkMode(String id) => _dashboardHomeEnterBulkMode(this, id);

  void _toggleSelection(String id) => _dashboardHomeToggleSelection(this, id);

  void _handleItemLongPress(String id) =>
      _dashboardHomeHandleItemLongPress(this, id);

  void _exitBulkMode() => _dashboardHomeExitBulkMode(this);

  void _pruneSelection(List<BaseCardDto> items) =>
      _dashboardHomePruneSelection(this, items);

  Future<void> _runBulkAction({
    required Future<void> Function(
      PaginatedListNotifier notifier,
      List<String> ids,
    )
    action,
    required String successTitle,
  }) => _dashboardHomeRunBulkAction(
    this,
    action: action,
    successTitle: successTitle,
  );

  Future<void> _showBulkDeleteDialog() =>
      _dashboardHomeShowBulkDeleteDialog(this);

  Future<void> _showBulkAssignCategoryDialog() =>
      _dashboardHomeShowBulkAssignCategoryDialog(this);

  Future<void> _showBulkAssignTagsDialog() =>
      _dashboardHomeShowBulkAssignTagsDialog(this);

  Future<void> _applyBulkArchive() => _dashboardHomeApplyBulkArchive(this);

  Future<void> _applyBulkFavorite() => _dashboardHomeApplyBulkFavorite(this);

  Future<void> _applyBulkPin() => _dashboardHomeApplyBulkPin(this);

  // Future<bool> _closeDatabase() => _dashboardHomeCloseDatabase(this);

  void _showCloseDatabaseDialog() =>
      _dashboardHomeShowCloseDatabaseDialog(this);

  @override
  Widget build(BuildContext context) =>
      _buildDashboardHomeScreen(this, context);

  Widget _buildContentSliver(
    AsyncValue<DashboardListState<BaseCardDto>> asyncValue,
    ViewMode viewMode,
  ) => _buildDashboardHomeContentSliver(this, asyncValue, viewMode);
}
