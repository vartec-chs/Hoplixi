import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/db_core/models/dto/index.dart';
import 'package:hoplixi/db_core/models/enums/index.dart';
import 'package:hoplixi/db_core/provider/main_store_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/base_filter_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/list_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_builders.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/app_bar/app_bar_widgets.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_list_toolbar.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_layout/dashboard_drawer_scope.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/widgets/category_picker_field.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/widgets/tag_picker_field.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Длительность анимации для элементов списка.
const kAnimationDuration = Duration(milliseconds: 180);

/// Экран дашборда со списком карточек.
///
/// Использует [SliverAnimatedList]/[SliverAnimatedGrid] для анимированного
/// отображения элементов с поддержкой diff-обновлений.
class DashboardHomeScreen extends ConsumerStatefulWidget {
  const DashboardHomeScreen({super.key, required this.entityType});

  final EntityType entityType;

  @override
  ConsumerState<DashboardHomeScreen> createState() =>
      _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends ConsumerState<DashboardHomeScreen> {
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

  /// Флаг первого построения — для начальной синхронизации.
  bool _isFirstBuild = true;

  /// Режим массового выбора элементов.
  bool _isBulkMode = false;

  /// Идентификаторы выбранных элементов.
  final Set<String> _selectedIds = <String>{};

  /// Защита от повторных bulk-операций.
  bool _isApplyingBulkAction = false;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _loadMoreDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DashboardHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // При смене entityType — сбрасываем список и синхронизируем
    if (oldWidget.entityType != widget.entityType) {
      _resetList();
      // Отложенная синхронизация с новым провайдером
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final items =
            ref.read(paginatedListProvider(widget.entityType)).value?.items ??
            [];
        _syncItems(items);
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Scroll & Pagination
  // ─────────────────────────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _kScrollThreshold) {
      _tryLoadMore();
    }
  }

  void _tryLoadMore() {
    if (_loadMoreDebounce?.isActive ?? false) return;
    _loadMoreDebounce = Timer(const Duration(milliseconds: 100), () {
      final state = ref.read(paginatedListProvider(widget.entityType)).value;
      if (state != null &&
          !state.isLoadingMore &&
          state.hasMore &&
          !state.isLoading) {
        ref.read(paginatedListProvider(widget.entityType).notifier).loadMore();
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // List synchronization
  // ─────────────────────────────────────────────────────────────────────────

  /// Синхронизирует [_displayedItems] с новым списком из провайдера.
  void _syncItems(List<BaseCardDto> newItems) {
    if (!mounted) return;

    final viewMode = ref.read(currentViewModeProvider);
    final listState = _listKey.currentState;
    final gridState = _gridKey.currentState;

    // Если анимированный список ещё не готов — просто копируем данные
    final animationReady = viewMode == ViewMode.list
        ? listState != null
        : gridState != null;

    if (!animationReady) {
      setState(() => _displayedItems = List.of(newItems));
      return;
    }

    if (!_shouldAnimateItems(newItems)) {
      _replaceItemsWithoutAnimation(newItems);
      return;
    }

    _performDiff(newItems, viewMode, listState, gridState);
  }

  bool _shouldAnimateItems(List<BaseCardDto> newItems) {
    final totalItems = newItems.length > _displayedItems.length
        ? newItems.length
        : _displayedItems.length;
    return totalItems <= kDashboardAnimatedItemsThreshold;
  }

  void _replaceItemsWithoutAnimation(List<BaseCardDto> newItems) {
    setState(() {
      _displayedItems = List.of(newItems);
      _isClearing = false;
      _listKey = GlobalKey<SliverAnimatedListState>();
      _gridKey = GlobalKey<SliverAnimatedGridState>();
    });
  }

  /// Выполняет diff между [_displayedItems] и [newItems] с анимациями.
  void _performDiff(
    List<BaseCardDto> newItems,
    ViewMode viewMode,
    SliverAnimatedListState? listState,
    SliverAnimatedGridState? gridState,
  ) {
    final newIds = newItems.map((e) => e.id).toSet();
    var didMutate = false;

    // 1. Удаление (с конца, чтобы не сбивать индексы)
    for (var i = _displayedItems.length - 1; i >= 0; i--) {
      final item = _displayedItems[i];
      if (!newIds.contains(item.id)) {
        _displayedItems.removeAt(i);
        didMutate = true;
        _animateRemove(i, item, viewMode, listState, gridState);
      }
    }

    // Если после удаления список опустел — показываем состояние «очистка»
    if (didMutate && newItems.isEmpty) {
      _isClearing = true;
      Timer(kAnimationDuration, () {
        if (mounted) setState(() => _isClearing = false);
      });
    }

    // 2. Вставка / обновление
    final indexById = <String, int>{
      for (var i = 0; i < _displayedItems.length; i++) _displayedItems[i].id: i,
    };

    for (var i = 0; i < newItems.length; i++) {
      final newItem = newItems[i];
      final id = newItem.id;

      if (i < _displayedItems.length && _displayedItems[i].id == id) {
        // Элемент на месте — проверяем, изменились ли данные
        if (_displayedItems[i] != newItem) {
          _displayedItems[i] = newItem;
          didMutate = true;
        }
        indexById[id] = i;
        continue;
      }

      final existingIndex = indexById[id];
      if (existingIndex != null && existingIndex >= i) {
        // Перемещение: убираем со старого места и вставляем на новое
        final moved = _displayedItems.removeAt(existingIndex);
        _animateRemove(existingIndex, moved, viewMode, listState, gridState);
        _displayedItems.insert(i, newItem);
        _animateInsert(i, viewMode, listState, gridState);
        // Пересчитываем карту после сдвига
        for (var j = i; j < _displayedItems.length; j++) {
          indexById[_displayedItems[j].id] = j;
        }
        didMutate = true;
      } else if (existingIndex == null) {
        // Новый элемент
        _displayedItems.insert(i, newItem);
        _animateInsert(i, viewMode, listState, gridState);
        // Сдвигаем индексы
        for (var j = i; j < _displayedItems.length; j++) {
          indexById[_displayedItems[j].id] = j;
        }
        didMutate = true;
      }
    }

    if (didMutate) setState(() {});
  }

  void _animateInsert(
    int index,
    ViewMode viewMode,
    SliverAnimatedListState? listState,
    SliverAnimatedGridState? gridState,
  ) {
    if (viewMode == ViewMode.list) {
      listState?.insertItem(index, duration: kAnimationDuration);
    } else {
      gridState?.insertItem(index, duration: kAnimationDuration);
    }
  }

  void _animateRemove(
    int index,
    BaseCardDto item,
    ViewMode viewMode,
    SliverAnimatedListState? listState,
    SliverAnimatedGridState? gridState,
  ) {
    Widget builder(BuildContext ctx, Animation<double> anim) {
      return DashboardHomeBuilders.buildRemovedItem(
        context: ctx,
        ref: ref,
        entityType: widget.entityType,
        item: item,
        animation: anim,
        viewMode: viewMode,
        callbacks: _callbacks,
      );
    }

    if (viewMode == ViewMode.list) {
      listState?.removeItem(index, builder, duration: kAnimationDuration);
    } else {
      gridState?.removeItem(index, builder, duration: kAnimationDuration);
    }
  }

  /// Локальное удаление элемента (для Dismissible — без анимации sliver).
  void _removeItemLocally(String id) {
    setState(() {
      _displayedItems.removeWhere((e) => e.id == id);
      _selectedIds.remove(id);
      if (_selectedIds.isEmpty) {
        _isBulkMode = false;
      }
    });
  }

  /// Сброс списка при смене entityType / viewMode.
  void _resetList() {
    _scrollToTopSafe();
    setState(() {
      _displayedItems = [];
      _isClearing = false;
      _isBulkMode = false;
      _selectedIds.clear();
      _listKey = GlobalKey<SliverAnimatedListState>();
      _gridKey = GlobalKey<SliverAnimatedGridState>();
    });
  }

  void _scrollToTopSafe() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (pos.hasContentDimensions && pos.pixels != 0) {
        _scrollController.jumpTo(0);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Callbacks
  // ─────────────────────────────────────────────────────────────────────────

  DashboardCardCallbacks get _callbacks =>
      DashboardCardCallbacks.fromRefWithLocalRemove(
        ref,
        widget.entityType,
        _removeItemLocally,
      );

  List<BaseCardDto> get _selectedItems => _displayedItems
      .where((item) => _selectedIds.contains(item.id))
      .toList(growable: false);

  void _openItemView(String id) {
    final viewPath = AppRoutesPaths.dashboardEntityView(widget.entityType, id);
    if (GoRouter.of(context).state.matchedLocation != viewPath) {
      context.push(viewPath);
    }
  }

  void _enterBulkMode(String id) {
    setState(() {
      _isBulkMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _isBulkMode = _selectedIds.isNotEmpty;
    });
  }

  void _handleItemLongPress(String id) {
    if (_isBulkMode) {
      _toggleSelection(id);
      return;
    }

    _enterBulkMode(id);
  }

  void _exitBulkMode() {
    if (!_isBulkMode && _selectedIds.isEmpty) {
      return;
    }

    setState(() {
      _isBulkMode = false;
      _selectedIds.clear();
    });
  }

  void _pruneSelection(List<BaseCardDto> items) {
    if (_selectedIds.isEmpty) {
      return;
    }

    final validIds = items.map((item) => item.id).toSet();
    final nextSelected = _selectedIds.intersection(validIds);

    if (nextSelected.length == _selectedIds.length) {
      return;
    }

    setState(() {
      _selectedIds
        ..clear()
        ..addAll(nextSelected);
      _isBulkMode = _selectedIds.isNotEmpty;
    });
  }

  Future<void> _runBulkAction({
    required Future<void> Function(
      PaginatedListNotifier notifier,
      List<String> ids,
    )
    action,
    required String successTitle,
  }) async {
    if (_selectedIds.isEmpty || _isApplyingBulkAction) {
      return;
    }

    final notifier = ref.read(
      paginatedListProvider(widget.entityType).notifier,
    );
    final selectedIds = _selectedIds.toList(growable: false);

    setState(() => _isApplyingBulkAction = true);

    try {
      await action(notifier, selectedIds);
      if (!mounted) {
        return;
      }
      _exitBulkMode();
      Toaster.success(title: successTitle);
    } catch (_) {
      if (!mounted) {
        return;
      }
      Toaster.error(title: 'Не удалось выполнить массовое действие');
    } finally {
      if (mounted) {
        setState(() => _isApplyingBulkAction = false);
      }
    }
  }

  Future<void> _showBulkDeleteDialog() async {
    if (_selectedIds.isEmpty || _isApplyingBulkAction) {
      return;
    }

    final selectedItems = _selectedItems;
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
                ? 'Будет безвозвратно удалено элементов: ${selectedItems.length}.'
                : 'Будет перемещено в удалённые элементов: ${selectedItems.length}.',
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

    if (shouldDelete != true) {
      return;
    }

    await _runBulkAction(
      action: (notifier, ids) =>
          notifier.bulkDelete(ids, permanently: isPermanentDelete),
      successTitle: isPermanentDelete
          ? 'Элементы удалены навсегда'
          : 'Элементы перемещены в удалённые',
    );
  }

  Future<void> _showBulkAssignCategoryDialog() async {
    if (_selectedIds.isEmpty || _isApplyingBulkAction) {
      return;
    }

    String? selectedCategoryId;
    String? selectedCategoryName;

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
                    widget.entityType.toCategoryType(),
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

    if (confirmed != true) {
      return;
    }

    await _runBulkAction(
      action: (notifier, ids) =>
          notifier.bulkAssignCategory(ids, selectedCategoryId),
      successTitle: selectedCategoryId == null
          ? 'Категория очищена'
          : 'Категория назначена',
    );
  }

  Future<void> _showBulkAssignTagsDialog() async {
    if (_selectedIds.isEmpty || _isApplyingBulkAction) {
      return;
    }

    List<String> selectedTagIds = <String>[];
    List<String> selectedTagNames = <String>[];

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
                  filterByType: [widget.entityType.toTagType(), TagType.mixed],
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

    if (confirmed != true) {
      return;
    }

    await _runBulkAction(
      action: (notifier, ids) => notifier.bulkAssignTags(ids, selectedTagIds),
      successTitle: selectedTagIds.isEmpty ? 'Теги очищены' : 'Теги обновлены',
    );
  }

  bool get _shouldArchiveSelection =>
      _selectedItems.any((item) => !item.isArchived);

  bool get _shouldFavoriteSelection =>
      _selectedItems.any((item) => !item.isFavorite);

  bool get _shouldPinSelection => _selectedItems.any((item) => !item.isPinned);

  Future<void> _applyBulkArchive() async {
    if (_selectedIds.isEmpty || _isApplyingBulkAction) {
      return;
    }

    final shouldArchive = _shouldArchiveSelection;

    await _runBulkAction(
      action: (notifier, ids) => notifier.bulkSetArchive(ids, shouldArchive),
      successTitle: shouldArchive
          ? 'Элементы перенесены в архив'
          : 'Элементы извлечены из архива',
    );
  }

  Future<void> _applyBulkFavorite() async {
    if (_selectedIds.isEmpty || _isApplyingBulkAction) {
      return;
    }

    final shouldFavorite = _shouldFavoriteSelection;

    await _runBulkAction(
      action: (notifier, ids) => notifier.bulkSetFavorite(ids, shouldFavorite),
      successTitle: shouldFavorite
          ? 'Элементы добавлены в избранное'
          : 'Элементы удалены из избранного',
    );
  }

  Future<void> _applyBulkPin() async {
    if (_selectedIds.isEmpty || _isApplyingBulkAction) {
      return;
    }

    final shouldPin = _shouldPinSelection;

    await _runBulkAction(
      action: (notifier, ids) => notifier.bulkSetPin(ids, shouldPin),
      successTitle: shouldPin ? 'Элементы закреплены' : 'Элементы откреплены',
    );
  }

  Future<void> _closeDatabase() async {
    final success = await ref.read(mainStoreProvider.notifier).closeStore();
    if (success) {
      if (mounted) {
        Toaster.info(title: 'База данных закрыта', description: '');
      }
    }
  }

  void _showCloseDatabaseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Закрыть базу данных?'),
          content: const Text('Вы уверены, что хотите закрыть базу данных?'),
          actions: <Widget>[
            SmoothButton(
              label: 'Нет',
              onPressed: () {
                Navigator.of(context).pop();
              },
              variant: .normal,
              size: .small,
              type: .text,
            ),
            SmoothButton(
              label: 'Да',
              onPressed: () async {
                Navigator.of(context).pop();
                await _closeDatabase();
                if (context.mounted) {
                  context.go(AppRoutesPaths.home);
                }
              },
              variant: .error,
              size: .small,
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(currentViewModeProvider);
    final asyncValue = ref.watch(paginatedListProvider(widget.entityType));
    Future.microtask(() {
      ref.read(baseFilterProvider.notifier).setEntityType(widget.entityType.id);
    });

    final disableAppBarMenu = MediaQuery.of(context).size.width <= 700;

    // Начальная синхронизация при первом построении
    if (_isFirstBuild) {
      _isFirstBuild = false;
      asyncValue.whenData((state) {
        // Синхронизируем сразу после первого build frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _displayedItems.isEmpty && state.items.isNotEmpty) {
            _syncItems(state.items);
          }
        });
      });
    }

    // ref.listen должен быть в build — согласно документации Riverpod
    ref.listen<AsyncValue<DashboardListState<BaseCardDto>>>(
      paginatedListProvider(widget.entityType),
      (prev, next) {
        next.whenData((state) {
          // Синхронизация после построения кадра
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncItems(state.items);
            _pruneSelection(state.items);
          });
        });
      },
    );

    // Сброс при смене viewMode (ключи list/grid несовместимы)
    ref.listen<ViewMode>(currentViewModeProvider, (prev, next) {
      if (prev != null && prev != next) {
        _resetList();
        // После сброса подгружаем текущие данные
        final items = asyncValue.value?.items ?? [];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncItems(items);
        });
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          if (_isBulkMode) {
            _exitBulkMode();
            return;
          }
          _showCloseDatabaseDialog();
        }
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => ref
              .read(paginatedListProvider(widget.entityType).notifier)
              .refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              DashboardSliverAppBar(
                entityType: widget.entityType,
                expandedHeight: 176.0,
                collapsedHeight: 60.0,
                pinned: true,
                floating: false,
                snap: false,
                showEntityTypeSelector: true,
                onMenuPressed: !disableAppBarMenu
                    ? null
                    : () {
                        final scope = DashboardDrawerScope.of(context);
                        if (scope != null) {
                          scope.openDrawer();
                        } else {
                          Scaffold.of(context).openDrawer();
                        }
                      },
              ),
              SliverToBoxAdapter(
                child: DashboardListToolBar(
                  entityType: widget.entityType,
                  viewMode: viewMode,
                  listState: asyncValue,
                  isBulkMode: _isBulkMode,
                  selectedCount: _selectedIds.length,
                  onExitBulkMode: _isApplyingBulkAction ? null : _exitBulkMode,
                  onBulkDelete: _isApplyingBulkAction
                      ? null
                      : _showBulkDeleteDialog,
                  onBulkFavorite: _isApplyingBulkAction
                      ? null
                      : _applyBulkFavorite,
                  bulkFavoriteLabel: _shouldFavoriteSelection
                      ? 'В избранное'
                      : 'Убрать из избранного',
                  onBulkPin: _isApplyingBulkAction ? null : _applyBulkPin,
                  bulkPinLabel: _shouldPinSelection ? 'Закрепить' : 'Открепить',
                  onBulkArchive: _isApplyingBulkAction
                      ? null
                      : _applyBulkArchive,
                  bulkArchiveLabel: _shouldArchiveSelection
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
              _buildContentSliver(asyncValue, viewMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentSliver(
    AsyncValue<DashboardListState<BaseCardDto>> asyncValue,
    ViewMode viewMode,
  ) {
    return DashboardHomeBuilders.buildContentSliver(
      context: context,
      ref: ref,
      entityType: widget.entityType,
      viewMode: viewMode,
      asyncValue: asyncValue,
      displayedItems: _displayedItems,
      isClearing: _isClearing,
      listKey: _listKey,
      gridKey: _gridKey,
      callbacks: _callbacks,
      isBulkMode: _isBulkMode,
      selectedIds: _selectedIds,
      onItemTap: _toggleSelection,
      onItemLongPress: _handleItemLongPress,
      onOpenView: _openItemView,
      onInvalidate: () =>
          ref.invalidate(paginatedListProvider(widget.entityType)),
    );
  }
}
