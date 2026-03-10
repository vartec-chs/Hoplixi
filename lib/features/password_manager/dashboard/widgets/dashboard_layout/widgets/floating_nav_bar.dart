import 'package:flutter/material.dart';

import '../dashboard_layout_constants.dart';
import 'floating_nav_item.dart';

/// Плавающий навигационный бар со скользящим индикатором
/// в стиле segment control.
///
/// Используется для мобильной навигации в DashboardLayout.
/// Индикатор анимируется через [AnimationController] для
/// гарантированной плавной анимации скольжения.
class FloatingNavBar extends StatefulWidget {
  /// Список пунктов навигации.
  final List<NavigationRailDestination> destinations;

  /// Индекс выбранного пункта.
  final int selectedIndex;

  /// Callback при выборе пункта.
  final ValueChanged<int> onItemSelected;

  const FloatingNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onItemSelected,
    super.key,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _positionAnimation;
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: kSegmentIndicatorDuration,
    );
    _positionAnimation = AlwaysStoppedAnimation(
      widget.selectedIndex.toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant FloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _positionAnimation =
          Tween<double>(
            begin: _previousIndex.toDouble(),
            end: widget.selectedIndex.toDouble(),
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemCount = widget.destinations.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(kFloatingNavBarBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).shadowColor.withValues(alpha: kFloatingNavShadowOpacity),
            blurRadius: kFloatingNavShadowBlurRadius,
            offset: const Offset(0, kFloatingNavShadowOffsetY),
          ),
        ],
      ),
      child: SizedBox(
        height: kFloatingNavBarHeight,
        child: Stack(
          children: [
            // Скользящий индикатор: Align+FractionallySizedBox вместо
            // LayoutBuilder+Positioned, чтобы не вызывать markNeedsLayout
            // в invokeLayoutCallback и не получать _RenderLayoutBuilder-конфликт.
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final position = _positionAnimation.value;
                // Выравнивание: левый край индикатора = position * (W / n)
                // → alignX = 2 * position / (n - 1) - 1 для n > 1.
                final alignX = itemCount > 1
                    ? 2.0 * position / (itemCount - 1) - 1.0
                    : 0.0;
                return Align(
                  alignment: Alignment(alignX, 0),
                  child: FractionallySizedBox(
                    widthFactor: 1.0 / itemCount,
                    heightFactor: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kSegmentIndicatorHorizontalPadding,
                        vertical: kSegmentIndicatorVerticalPadding,
                      ),
                      child: child,
                    ),
                  ),
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            // Элементы навигации
            Row(
              children: widget.destinations
                  .asMap()
                  .entries
                  .map(
                    (entry) => Expanded(
                      child: FloatingNavItem(
                        destination: entry.value,
                        isSelected: widget.selectedIndex == entry.key,
                        onTap: () => widget.onItemSelected(entry.key),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
