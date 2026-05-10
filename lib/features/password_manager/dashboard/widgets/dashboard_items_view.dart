import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/settings/providers/settings_prefs_providers.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';

import '../models/dashboard_view_mode.dart';
import 'entity_cards/dashboard_entity_card_builder.dart';

const _dashboardItemAnimationDuration = Duration(milliseconds: 180);

final class DashboardItemsView extends ConsumerStatefulWidget {
  const DashboardItemsView({
    required this.items,
    required this.viewMode,
    required this.selectedIds,
    required this.onOpen,
    required this.onOpenEdit,
    required this.onToggleSelection,
    required this.onStartSelection,
    required this.onToggleFavorite,
    required this.onTogglePinned,
    required this.onToggleArchived,
    required this.onDelete,
    required this.onRestore,
    required this.onOpenView,
    required this.onOpenHistory,
    super.key,
  });

  final List<BaseCardDto> items;
  final DashboardViewMode viewMode;
  final Set<String> selectedIds;
  final ValueChanged<BaseCardDto> onOpen;
  final ValueChanged<BaseCardDto> onOpenEdit;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<String> onStartSelection;
  final ValueChanged<BaseCardDto> onToggleFavorite;
  final ValueChanged<BaseCardDto> onTogglePinned;
  final ValueChanged<BaseCardDto> onToggleArchived;
  final ValueChanged<BaseCardDto> onDelete;
  final ValueChanged<BaseCardDto> onRestore;
  final ValueChanged<BaseCardDto> onOpenView;
  final ValueChanged<BaseCardDto> onOpenHistory;

  @override
  ConsumerState<DashboardItemsView> createState() => _DashboardItemsViewState();
}

final class _DashboardItemsViewState extends ConsumerState<DashboardItemsView> {
  var _displayedItems = <BaseCardDto>[];
  var _listKey = GlobalKey<SliverAnimatedListState>();
  var _gridKey = GlobalKey<SliverAnimatedGridState>();
  var _isClearing = false;

  @override
  void initState() {
    super.initState();
    _displayedItems = List.of(widget.items);
  }

  @override
  void didUpdateWidget(covariant DashboardItemsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.viewMode != widget.viewMode) {
      _replaceItemsWithoutAnimation(widget.items);
      return;
    }

    _syncItems(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedItems.isEmpty && !_isClearing) {
      return const _EmptyDashboardList();
    }

    final animationsEnabled =
        ref.watch(dashboardAnimationsEnabledProvider).value ?? true;
    final animatedItemsThreshold =
        ref.watch(dashboardAnimatedItemsThresholdProvider).value ?? 15;
    final useAnimatedSliver =
        animationsEnabled && _displayedItems.length <= animatedItemsThreshold;

    if (!useAnimatedSliver) {
      return widget.viewMode.isGrid ? _buildStaticGrid() : _buildStaticList();
    }

    return widget.viewMode.isGrid ? _buildAnimatedGrid() : _buildAnimatedList();
  }

  Widget _buildAnimatedGrid() {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.crossAxisExtent / 360).floor().clamp(1, 4);

        return SliverAnimatedGrid(
          key: _gridKey,
          initialItemCount: _displayedItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 220,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index, animation) {
            if (index >= _displayedItems.length) {
              return const SizedBox.shrink();
            }
            return _itemTransition(
              item: _displayedItems[index],
              animation: animation,
              playEntrance: true,
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedList() {
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _displayedItems.length,
      itemBuilder: (context, index, animation) {
        if (index >= _displayedItems.length) {
          return const SizedBox.shrink();
        }
        return _itemTransition(
          item: _displayedItems[index],
          animation: animation,
          playEntrance: true,
        );
      },
    );
  }

  Widget _buildStaticGrid() {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.crossAxisExtent / 360).floor().clamp(1, 4);
        return SliverGrid.builder(
          itemCount: _displayedItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 220,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) => _itemCard(_displayedItems[index]),
        );
      },
    );
  }

  Widget _buildStaticList() {
    return SliverList.builder(
      itemCount: _displayedItems.length * 2 - 1,
      itemBuilder: (context, index) {
        if (index.isOdd) return const SizedBox(height: 6);
        return _itemCard(_displayedItems[index ~/ 2]);
      },
    );
  }

  Widget _itemTransition({
    required BaseCardDto item,
    required Animation<double> animation,
    required bool playEntrance,
  }) {
    final transition = FadeScaleTransition(
      animation: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: Padding(
          padding: widget.viewMode.isGrid
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: 6),
          child: _itemCard(item),
        ),
      ),
    );

    if (!playEntrance) return transition;

    return _DashboardItemEntranceTransition(itemId: item.id, child: transition);
  }

  Widget _itemCard(BaseCardDto item) {
    return DashboardEntityCardBuilder.build(
      item: item,
      viewMode: widget.viewMode,
      selectedIds: widget.selectedIds,
      actions: DashboardEntityCardActions(
        onOpen: widget.onOpen,
        onOpenEdit: widget.onOpenEdit,
        onToggleSelection: widget.onToggleSelection,
        onStartSelection: widget.onStartSelection,
        onToggleFavorite: widget.onToggleFavorite,
        onTogglePinned: widget.onTogglePinned,
        onToggleArchived: widget.onToggleArchived,
        onDelete: widget.onDelete,
        onRestore: widget.onRestore,
        onOpenView: widget.onOpenView,
        onOpenHistory: widget.onOpenHistory,
      ),
    );
  }

  void _syncItems(List<BaseCardDto> newItems) {
    if (!mounted) return;

    final animationsEnabled =
        ref.read(dashboardAnimationsEnabledProvider).value ?? true;
    if (!animationsEnabled || !_shouldAnimateItems(newItems)) {
      _replaceItemsWithoutAnimation(newItems);
      return;
    }

    final listState = _listKey.currentState;
    final gridState = _gridKey.currentState;
    final animationReady = widget.viewMode.isGrid
        ? gridState != null
        : listState != null;

    if (!animationReady) {
      setState(() => _displayedItems = List.of(newItems));
      return;
    }

    _performDiff(newItems, listState, gridState);
  }

  bool _shouldAnimateItems(List<BaseCardDto> newItems) {
    final totalItems = newItems.length > _displayedItems.length
        ? newItems.length
        : _displayedItems.length;
    final animatedItemsThreshold =
        ref.read(dashboardAnimatedItemsThresholdProvider).value ?? 15;
    return totalItems <= animatedItemsThreshold;
  }

  void _replaceItemsWithoutAnimation(List<BaseCardDto> newItems) {
    setState(() {
      _displayedItems = List.of(newItems);
      _isClearing = false;
      _listKey = GlobalKey<SliverAnimatedListState>();
      _gridKey = GlobalKey<SliverAnimatedGridState>();
    });
  }

  void _performDiff(
    List<BaseCardDto> newItems,
    SliverAnimatedListState? listState,
    SliverAnimatedGridState? gridState,
  ) {
    final newIds = newItems.map((item) => item.id).toSet();
    var didMutate = false;

    for (var i = _displayedItems.length - 1; i >= 0; i--) {
      final item = _displayedItems[i];
      if (!newIds.contains(item.id)) {
        _displayedItems.removeAt(i);
        didMutate = true;
        _animateRemove(i, item, listState, gridState);
      }
    }

    if (didMutate && newItems.isEmpty) {
      _isClearing = true;
      Timer(_dashboardItemAnimationDuration, () {
        if (mounted) setState(() => _isClearing = false);
      });
    }

    final indexById = <String, int>{
      for (var i = 0; i < _displayedItems.length; i++) _displayedItems[i].id: i,
    };

    for (var i = 0; i < newItems.length; i++) {
      final newItem = newItems[i];
      final id = newItem.id;

      if (i < _displayedItems.length && _displayedItems[i].id == id) {
        if (_displayedItems[i] != newItem) {
          _displayedItems[i] = newItem;
          didMutate = true;
        }
        indexById[id] = i;
        continue;
      }

      final existingIndex = indexById[id];
      if (existingIndex != null && existingIndex >= i) {
        final movedItem = _displayedItems.removeAt(existingIndex);
        _animateRemove(existingIndex, movedItem, listState, gridState);
        _displayedItems.insert(i, newItem);
        _animateInsert(i, listState, gridState);
        _refreshIndexMap(indexById, i);
        didMutate = true;
      } else if (existingIndex == null) {
        _displayedItems.insert(i, newItem);
        _animateInsert(i, listState, gridState);
        _refreshIndexMap(indexById, i);
        didMutate = true;
      }
    }

    if (didMutate) setState(() {});
  }

  void _refreshIndexMap(Map<String, int> indexById, int fromIndex) {
    for (var i = fromIndex; i < _displayedItems.length; i++) {
      indexById[_displayedItems[i].id] = i;
    }
  }

  void _animateInsert(
    int index,
    SliverAnimatedListState? listState,
    SliverAnimatedGridState? gridState,
  ) {
    if (widget.viewMode.isGrid) {
      gridState?.insertItem(index, duration: _dashboardItemAnimationDuration);
      return;
    }

    listState?.insertItem(index, duration: _dashboardItemAnimationDuration);
  }

  void _animateRemove(
    int index,
    BaseCardDto item,
    SliverAnimatedListState? listState,
    SliverAnimatedGridState? gridState,
  ) {
    Widget builder(BuildContext context, Animation<double> animation) {
      return _itemTransition(
        item: item,
        animation: animation,
        playEntrance: false,
      );
    }

    if (widget.viewMode.isGrid) {
      gridState?.removeItem(
        index,
        builder,
        duration: _dashboardItemAnimationDuration,
      );
      return;
    }

    listState?.removeItem(
      index,
      builder,
      duration: _dashboardItemAnimationDuration,
    );
  }
}

final class _DashboardItemEntranceTransition extends StatelessWidget {
  const _DashboardItemEntranceTransition({
    required this.itemId,
    required this.child,
  });

  final String itemId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('dashboard-v2-item-entrance-$itemId'),
      tween: Tween(begin: 0, end: 1),
      duration: _dashboardItemAnimationDuration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: Transform.scale(scale: 0.98 + value * 0.02, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

final class _EmptyDashboardList extends StatelessWidget {
  const _EmptyDashboardList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ничего не найдено',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
