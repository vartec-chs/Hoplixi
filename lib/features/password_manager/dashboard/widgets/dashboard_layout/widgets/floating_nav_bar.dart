import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/dashboard_layout_constants.dart';
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

  /// Включает glass blur и полупрозрачный фон панели.
  final bool visualEffectsEnabled;

  const FloatingNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onItemSelected,
    this.visualEffectsEnabled = true,
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
    final borderRadius = BorderRadius.circular(kFloatingNavBarBorderRadius);
    final navBarContent = SizedBox(
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
                color: colorScheme.primaryContainer.withValues(
                  alpha: widget.visualEffectsEnabled ? 0.16 : 0.1,
                ),
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
    );
    final navBarSurface = widget.visualEffectsEnabled
        ? BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
                    colorScheme.surfaceContainer.withValues(alpha: 0.48),
                  ],
                ),
                borderRadius: borderRadius,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.28),
                ),
              ),
              child: navBarContent,
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: borderRadius,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.18),
              ),
            ),
            child: navBarContent,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
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
      child: ClipRRect(borderRadius: borderRadius, child: navBarSurface),
    );
  }
}
