import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/list_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/list_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_builders.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/app_bar/app_bar_widgets.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_list_toolbar.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

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

    _performDiff(newItems, viewMode, listState, gridState);
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
    setState(() => _displayedItems.removeWhere((e) => e.id == id));
  }

  /// Сброс списка при смене entityType / viewMode.
  void _resetList() {
    _scrollToTopSafe();
    setState(() {
      _displayedItems = [];
      _isClearing = false;
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

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(currentViewModeProvider);
    final asyncValue = ref.watch(paginatedListProvider(widget.entityType));

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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(paginatedListProvider(widget.entityType).notifier)
            .refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            DashboardSliverAppBar(
              entityType: widget.entityType,
              expandedHeight: 178.0,
              collapsedHeight: 60.0,
              pinned: true,
              floating: false,
              snap: false,
              showEntityTypeSelector: true,
            ),
            SliverToBoxAdapter(
              child: DashboardListToolBar(
                entityType: widget.entityType,
                viewMode: viewMode,
                listState: asyncValue,
              ),
            ),
            _buildContentSliver(asyncValue, viewMode),
          ],
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
      onInvalidate: () =>
          ref.invalidate(paginatedListProvider(widget.entityType)),
    );
  }
}
