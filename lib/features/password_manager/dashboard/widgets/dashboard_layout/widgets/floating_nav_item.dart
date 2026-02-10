import 'package:flutter/material.dart';

import '../dashboard_layout_constants.dart';

/// Элемент плавающей навигационной панели.
///
/// Отображает иконку и метку с анимированным переключением цветов
/// при выборе/снятии выбора.
class FloatingNavItem extends StatelessWidget {
  /// Данные пункта навигации.
  final NavigationRailDestination destination;

  /// Выбран ли данный пункт.
  final bool isSelected;

  /// Callback при нажатии.
  final VoidCallback onTap;

  const FloatingNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kFloatingNavItemBorderRadius),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kFloatingNavItemPaddingH,
              vertical: kFloatingNavItemPaddingV,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedDefaultTextStyle(
                  duration: kSegmentIndicatorDuration,
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  child: IconTheme(
                    data: IconThemeData(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: kFloatingNavIconSize,
                    ),
                    child: destination.icon,
                  ),
                ),
                const SizedBox(height: kFloatingNavLabelSpacing),
                AnimatedDefaultTextStyle(
                  duration: kSegmentIndicatorDuration,
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: kFloatingNavLabelFontSize,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text((destination.label as Text).data ?? ''),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
