import 'package:flutter/material.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer.dart';

import 'dashboard_layout_constants.dart';
import 'widgets/fab_builder.dart';

/// Desktop-специфичный layout для DashboardLayout.
///
/// Отображает трёхколоночный layout с NavigationRail,
/// левой панелью фильтрации и анимированной правой панелью.
class DesktopDashboardLayout extends StatelessWidget {
  /// Текущий entity (passwords, notes, etc.)
  final String entity;

  /// Текущий URI
  final String uri;

  /// Контент панели
  final Widget panelChild;

  /// Показывать ли панель
  final bool hasPanel;

  /// Находится ли в режиме full-center
  final bool isFullCenter;

  /// Destinations для навигации
  final List<NavigationRailDestination> destinations;

  /// Текущий индекс навигации
  final int? selectedIndex;

  /// Callback при выборе пункта навигации
  final ValueChanged<int> onNavItemSelected;

  /// Контроллер анимации панели
  final Animation<double> panelAnimation;

  const DesktopDashboardLayout({
    required this.entity,
    required this.uri,
    required this.panelChild,
    required this.hasPanel,
    required this.isFullCenter,
    required this.destinations,
    required this.selectedIndex,
    required this.onNavItemSelected,
    required this.panelAnimation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showDrawerAsPanel = screenWidth >= MainConstants.kDesktopBreakpoint;
    // При широком разрешении левая панель остаётся видимой
    final isWideScreen = screenWidth >= MainConstants.kWideDesktopBreakpoint;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // NavigationRail / left menu
              _buildNavigationRail(context),
              const VerticalDivider(width: 1, thickness: 1),

              // Левая панель фильтрации для экранов >= 1000px
              if (showDrawerAsPanel && !isFullCenter)
                _buildLeftPanel(context, isWideScreen),

              // Center content
              Expanded(child: _buildCenterContent(context, showDrawerAsPanel)),

              // Анимированная правая панель
              if (!isFullCenter)
                _buildRightPanel(
                  context,
                  constraints,
                  showDrawerAsPanel,
                  isWideScreen,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationRail(
      unselectedIconTheme: IconThemeData(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w400,
      ),
      selectedIconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      selectedLabelTextStyle: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w400,
      ),
      indicatorColor: theme.colorScheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kIndicatorBorderRadius),
      ),
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      selectedIndex: selectedIndex,
      onDestinationSelected: onNavItemSelected,
      labelType: NavigationRailLabelType.all,
      destinations: destinations,
      leading: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: DashboardFabBuilder(
          context: context,
          entity: entity,
          currentAction: null,
          isMobile: false,
        ).buildExpandableFAB(),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context, bool isWideScreen) {
    // При широком разрешении панель всегда видна полностью
    if (isWideScreen) {
      return Container(
        width: kLeftPanelWidth,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        child: DashboardDrawerContent(entityType: EntityType.fromId(entity)!),
      );
    }

    // При обычном desktop разрешении панель анимируется
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: panelAnimation,
        builder: (context, child) {
          // Левая панель сворачивается когда правая открывается
          final leftPanelWidthAnimated =
              kLeftPanelWidth * (1.0 - panelAnimation.value);
          return SizedBox(
            width: leftPanelWidthAnimated,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: kLeftPanelWidth,
                maxWidth: kLeftPanelWidth,
                child: AnimatedOpacity(
                  opacity: 1.0 - panelAnimation.value,
                  duration: kOpacityAnimationDuration,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: Container(
          width: kLeftPanelWidth,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: DashboardDrawerContent(entityType: EntityType.fromId(entity)!),
        ),
      ),
    );
  }

  Widget _buildCenterContent(BuildContext context, bool showDrawerAsPanel) {
    return Stack(
      children: [
        // DashboardHomeScreen — всегда видим, скрывается только при isFullCenter
        AnimatedOpacity(
          opacity: isFullCenter ? 0.0 : 1.0,
          duration: kFadeAnimationDuration,
          curve: isFullCenter ? Curves.easeOut : Curves.easeIn,
          child: AnimatedScale(
            scale: isFullCenter ? kCenterScaleWhenFullCenter : 1.0,
            duration: kPanelAnimationDuration,
            curve: Curves.easeInOut,
            child: IgnorePointer(
              ignoring: isFullCenter,
              child: RepaintBoundary(
                child: DashboardHomeScreen(
                  entityType: EntityType.fromId(entity)!,
                  showDrawerButton: !showDrawerAsPanel,
                ),
              ),
            ),
          ),
        ),
        // Full-center content с анимацией появления
        if (isFullCenter)
          TweenAnimationBuilder<double>(
            key: ValueKey('fullCenter-$uri'),
            tween: Tween(begin: kFadeBegin, end: kFadeEnd),
            duration: kPanelAnimationDuration,
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale:
                      kFullCenterScaleBegin + (kFullCenterScaleOffset * value),
                  child: child,
                ),
              );
            },
            child: panelChild,
          ),
      ],
    );
  }

  Widget _buildRightPanel(
    BuildContext context,
    BoxConstraints constraints,
    bool showDrawerAsPanel,
    bool isWideScreen,
  ) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: panelAnimation,
        builder: (context, child) {
          // Вычисляем доступное пространство для центра и правой панели
          const railWidth = kRailWidth;
          // При широком разрешении левая панель не сворачивается
          final leftPanelWidth = (showDrawerAsPanel && !isFullCenter)
              ? isWideScreen
                    ? kLeftPanelWidth
                    : kLeftPanelWidth * (1.0 - panelAnimation.value)
              : 0.0;
          final availableWidth =
              constraints.maxWidth - railWidth - leftPanelWidth - kDividerWidth;

          final rightPanelMaxWidth = availableWidth * 0.5;
          final rightPanelWidthAnimated =
              rightPanelMaxWidth * panelAnimation.value;

          return SizedBox(
            width: rightPanelWidthAnimated,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: rightPanelMaxWidth,
                maxWidth: rightPanelMaxWidth,
                child: Container(
                  width: rightPanelMaxWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: AnimatedOpacity(
                    opacity: panelAnimation.value,
                    duration: kOpacityAnimationDuration,
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
        child: KeyedSubtree(key: ValueKey(uri), child: panelChild),
      ),
    );
  }
}
