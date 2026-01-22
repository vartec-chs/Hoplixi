import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/current_view_mode_provider.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class EntitySliverList<T extends BaseCardDto> extends StatefulWidget {
  final List<T> items;
  final ViewMode viewMode;
  final Widget Function(BuildContext context, T item) listBuilder;
  final Widget Function(BuildContext context, T item)? gridBuilder;
  final void Function(T item)? onTap;
  final void Function(T item)? onLongPress;
  final Duration animationDuration;
  final Curve animationCurve;

  const EntitySliverList({
    super.key,
    required this.items,
    required this.viewMode,
    required this.listBuilder,
    this.gridBuilder,
    this.onTap,
    this.onLongPress,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutCubic,
  });

  @override
  State<EntitySliverList<T>> createState() => _EntitySliverListState<T>();
}

class _EntitySliverListState<T extends BaseCardDto>
    extends State<EntitySliverList<T>> {
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey();
  final GlobalKey<SliverAnimatedGridState> _gridKey = GlobalKey();
  late List<T> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(EntitySliverList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.viewMode != oldWidget.viewMode) {
      _items = List.from(widget.items);
      return;
    }

    _updateList(widget.items);
  }

  void _updateList(List<T> newItems) {
    final currentState = widget.viewMode == ViewMode.list
        ? _listKey.currentState
        : _gridKey.currentState;

    // Если ключи еще не привязаны или состояние потеряно
    if (currentState == null && widget.viewMode == ViewMode.list) {
      if (_listKey.currentState == null) {
        _items = List.from(newItems);
        return;
      }
    } else if (currentState == null && widget.viewMode == ViewMode.grid) {
      if (_gridKey.currentState == null) {
        _items = List.from(newItems);
        return;
      }
    }

    // 1. Удаление элементов, которых нет в новом списке
    for (int i = _items.length - 1; i >= 0; i--) {
      final item = _items[i];
      if (!newItems.any((e) => e.id == item.id)) {
        final removedItem = _items.removeAt(i);
        if (widget.viewMode == ViewMode.list) {
          _listKey.currentState?.removeItem(
            i,
            (context, animation) =>
                _buildRemovedItem(removedItem, context, animation),
            duration: widget.animationDuration,
          );
        } else {
          _gridKey.currentState?.removeItem(
            i,
            (context, animation) =>
                _buildRemovedItem(removedItem, context, animation),
            duration: widget.animationDuration,
          );
        }
      }
    }

    // 2. Вставка новых элементов и обновление существующих
    for (int i = 0; i < newItems.length; i++) {
      final newItem = newItems[i];
      final currentIndex = _items.indexWhere((e) => e.id == newItem.id);

      if (currentIndex == -1) {
        // Вставка
        _items.insert(i, newItem);
        if (widget.viewMode == ViewMode.list) {
          _listKey.currentState?.insertItem(
            i,
            duration: widget.animationDuration,
          );
        } else {
          _gridKey.currentState?.insertItem(
            i,
            duration: widget.animationDuration,
          );
        }
      } else {
        // Обновление данных
        if (currentIndex != i) {
          // Если порядок изменился, просто перемещаем в локальном списке
          // SliverAnimatedList не поддерживает анимацию перемещения из коробки
          final item = _items.removeAt(currentIndex);
          _items.insert(i, item);
        }
        _items[i] = newItem;
      }
    }

    // Принудительно обновляем UI для отображения изменений данных/порядка
    setState(() {});
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    Animation<double> animation,
  ) {
    // Защита от выхода за границы массива при быстрых обновлениях
    if (index >= _items.length) return const SizedBox.shrink();

    final item = _items[index];
    return _buildTransition(context, item, animation);
  }

  Widget _buildRemovedItem(
    T item,
    BuildContext context,
    Animation<double> animation,
  ) {
    return _buildTransition(context, item, animation);
  }

  Widget _buildTransition(
    BuildContext context,
    T item,
    Animation<double> animation,
  ) {
    final child = widget.viewMode == ViewMode.list
        ? widget.listBuilder(context, item)
        : (widget.gridBuilder ?? widget.listBuilder)(context, item);

    final wrappedChild = widget.onTap != null || widget.onLongPress != null
        ? GestureDetector(
            onTap: () => widget.onTap?.call(item),
            onLongPress: () => widget.onLongPress?.call(item),
            child: child,
          )
        : child;

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: widget.animationCurve),
            ),
        child: wrappedChild,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && widget.items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('Список пуст')),
      );
    }

    if (widget.viewMode == ViewMode.list) {
      return SliverAnimatedList(
        key: _listKey,
        initialItemCount: _items.length,
        itemBuilder: _buildItem,
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        sliver: SliverAnimatedGrid(
          key: _gridKey,
          initialItemCount: _items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemBuilder: _buildItem,
        ),
      );
    }
  }
}
