import 'package:flutter/material.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer.dart';
import 'package:universal_platform/universal_platform.dart';

import 'dashboard_layout_constants.dart';
import 'widgets/fab_builder.dart';
import 'widgets/floating_nav_bar.dart';

/// Mobile-специфичный layout для DashboardLayout.
///
/// Отображает Stack с анимированными панелями,
/// floating bottom navigation и FAB.
class MobileDashboardLayout extends StatelessWidget {
  /// Текущий entity (passwords, notes, etc.)
  final String entity;

  /// Текущий URI
  final String uri;

  /// Контент панели
  final Widget panelChild;

  /// Показывать ли панель
  final bool showPanel;

  /// Показывать ли bottom navigation
  final bool showBottomNav;

  /// Показывать ли FAB
  final bool showFAB;

  /// Текущее действие (categories, tags, icons)
  final String? currentAction;

  /// Destinations для навигации
  final List<NavigationRailDestination> destinations;

  /// Callback при выборе пункта навигации
  final ValueChanged<int> onNavItemSelected;

  /// Текущий индекс навигации
  final int selectedIndex;

  const MobileDashboardLayout({
    required this.entity,
    required this.uri,
    required this.panelChild,
    required this.showPanel,
    required this.showBottomNav,
    required this.showFAB,
    required this.currentAction,
    required this.destinations,
    required this.onNavItemSelected,
    required this.selectedIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final systemPadding = MediaQuery.of(context).viewPadding;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showDrawerAsPanel = screenWidth >= MainConstants.kDesktopBreakpoint;

    return Scaffold(
      extendBody: true,
      drawer: DashboardDrawer(
        entityType: EntityType.fromId(entity) ?? EntityType.password,
      ),
      body: Stack(
        children: [
          // Центр: DashboardHomeScreen с обратной анимацией
          AnimatedOpacity(
            opacity: showPanel ? 0.0 : 1.0,
            duration: kFadeAnimationDuration,
            curve: showPanel ? Curves.easeOut : Curves.easeIn,
            child: AnimatedScale(
              scale: showPanel ? kCenterScaleWhenPanelOpen : 1.0,
              duration: kScaleAnimationDuration,
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: showPanel,
                child: RepaintBoundary(
                  child: DashboardHomeScreen(
                    entityType: EntityType.fromId(entity)!,
                    showDrawerButton: !showDrawerAsPanel,
                  ),
                ),
              ),
            ),
          ),

          // Анимированная панель поверх центра
          IgnorePointer(
            ignoring: !showPanel,
            child: AnimatedOpacity(
              duration: kFadeAnimationDuration,
              opacity: showPanel ? 1.0 : 0.0,
              curve: showPanel ? Curves.easeOut : Curves.easeIn,
              child: AnimatedScale(
                scale: showPanel ? kPanelZoomEnd : kPanelZoomBegin,
                duration: kScaleAnimationDuration,
                curve: Curves.easeOut,
                child: Container(key: ValueKey(uri), child: panelChild),
              ),
            ),
          ),

          // Floating bottom navigation bar с анимацией появления/исчезновения
          Positioned(
            bottom: UniversalPlatform.isDesktop
                ? kBottomNavNotchMargin
                : systemPadding.bottom,
            left: kFloatingNavMarginHorizontal,
            right: kFloatingNavMarginHorizontal,
            child: IgnorePointer(
              ignoring: !showBottomNav,
              child: AnimatedSlide(
                offset: showBottomNav ? Offset.zero : const Offset(0, 1.5),
                duration: kScaleAnimationDuration,
                curve: showBottomNav ? Curves.easeOutCubic : Curves.easeInCubic,
                child: AnimatedOpacity(
                  opacity: showBottomNav ? 1.0 : 0.0,
                  duration: kFadeAnimationDuration,
                  curve: Curves.easeInOut,
                  child: AnimatedScale(
                    scale: showBottomNav ? 1.0 : 0.95,
                    duration: kScaleAnimationDuration,
                    curve: showBottomNav ? Curves.easeOutBack : Curves.easeIn,
                    child: FloatingNavBar(
                      destinations: destinations,
                      selectedIndex: selectedIndex,
                      onItemSelected: onNavItemSelected,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // FAB выше floating nav
          Positioned(
            bottom: showBottomNav && UniversalPlatform.isDesktop
                ? kFloatingNavFabBottomOffset + kFloatingNavBarHeight + 5
                : systemPadding.bottom +
                      kFloatingNavFabBottomOffset +
                      kFloatingNavBarHeight,
            left: null,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.only(
                right: kFloatingNavMarginHorizontal,
              ),
              child: AnimatedOpacity(
                opacity: showFAB ? 1.0 : 0.0,
                duration: kOpacityAnimationDuration,
                curve: showFAB ? Curves.easeOutBack : Curves.easeIn,
                child: AnimatedSlide(
                  offset: showBottomNav ? Offset.zero : const Offset(0, 1.5),
                  duration: kFadeAnimationDuration,
                  curve: Curves.easeInOut,
                  child: IgnorePointer(
                    ignoring: !showFAB,
                    child: DashboardFabBuilder(
                      context: context,
                      entity: entity,
                      currentAction: currentAction,
                      isMobile: true,
                    ).buildExpandableFAB(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
