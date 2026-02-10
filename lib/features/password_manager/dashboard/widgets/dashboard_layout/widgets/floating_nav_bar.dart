import 'package:flutter/material.dart';

import '../dashboard_layout_constants.dart';
import 'floating_nav_item.dart';

/// Плавающий навигационный бар со скользящим индикатором
/// в стиле segment control.
///
/// Используется для мобильной навигации в DashboardLayout.
class FloatingNavBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemCount = destinations.length;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final itemWidth = totalWidth / itemCount;
            final indicatorLeft =
                selectedIndex * itemWidth + kSegmentIndicatorHorizontalPadding;
            final indicatorWidth =
                itemWidth - kSegmentIndicatorHorizontalPadding * 2;

            return Stack(
              children: [
                // Скользящий индикатор
                AnimatedPositioned(
                  duration: kSegmentIndicatorDuration,
                  curve: Curves.easeOutCubic,
                  left: indicatorLeft,
                  top: kSegmentIndicatorVerticalPadding,
                  bottom: kSegmentIndicatorVerticalPadding,
                  width: indicatorWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                // Элементы навигации
                Row(
                  children: destinations
                      .asMap()
                      .entries
                      .map(
                        (entry) => Expanded(
                          child: FloatingNavItem(
                            destination: entry.value,
                            isSelected: selectedIndex == entry.key,
                            onTap: () => onItemSelected(entry.key),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
