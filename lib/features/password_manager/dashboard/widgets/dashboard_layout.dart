import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/dashboard_destination.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/dashboard_fab_action.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/dashboard_route_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/entity_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/expandable_fab.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:universal_platform/universal_platform.dart';

import 'smooth_rounded_notched_rectangle.dart';

// Статическая ссылка на текущее состояние DashboardLayout
// Используйте DashboardLayout.currentState для доступа к методам:
// - closeSidebar() - закрыть sidebar
// - openSidebar() - открыть sidebar
// - toggleSidebar() - переключить состояние sidebar
// - isSidebarOpen - проверить, открыт ли sidebar
DashboardLayoutState? _dashboardLayoutState;

/// @Deprecated Используйте DashboardLayout.currentState вместо этого
/// Оставлено для обратной совместимости
final GlobalKey<DashboardLayoutState> dashboardSidebarKey =
    GlobalKey<DashboardLayoutState>();

/// Адаптивный layout для dashboard с использованием ShellRoute.
///
/// На больших экранах: NavigationRail слева + main content + sidebar справа (child)
/// На маленьких экранах: BottomNavigationBar + main content, sidebar открывается по отдельным роутам
///
/// ## Управление sidebar
///
/// Используйте `DashboardLayout.currentState` для управления sidebar из любого места:
/// ```dart
/// DashboardLayout.currentState?.closeSidebar();
/// DashboardLayout.currentState?.openSidebar();
/// DashboardLayout.currentState?.toggleSidebar();
/// final isOpen = DashboardLayout.currentState?.isSidebarOpen ?? false;
/// ```
///
/// ## Конфигурация маршрутов
///
/// Для добавления новых full-screen или sidebar маршрутов используйте
/// [DashboardRouteState] — централизованную конфигурацию в
/// `dashboard_route_state.dart`.
class DashboardLayout extends ConsumerStatefulWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  /// Текущее состояние DashboardLayout
  /// Может быть null если DashboardLayout ещё не создан
  static DashboardLayoutState? get currentState => _dashboardLayoutState;

  @override
  ConsumerState<DashboardLayout> createState() => DashboardLayoutState();
}

class DashboardLayoutState extends ConsumerState<DashboardLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;

  // Кэш предыдущего состояния для оптимизации анимаций
  DashboardRouteState? _previousRouteState;

  final GlobalKey<ExpandableFABState> _fabKey = GlobalKey();
  final GlobalKey<ExpandableFABState> _mobileFabKey = GlobalKey();

  // ===========================================================================
  // Screen Protection (Mobile)
  // ===========================================================================

  Future<void> _enableScreenProtection() async {
    if (UniversalPlatform.isMobile) {
      await ScreenProtector.protectDataLeakageOn();
      await ScreenProtector.protectDataLeakageWithBlur();
    }
  }

  Future<void> _disableScreenProtection() async {
    if (UniversalPlatform.isMobile) {
      await ScreenProtector.protectDataLeakageOff();
    }
  }

  // ===========================================================================
  // Lifecycle
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _dashboardLayoutState = this;
    _enableScreenProtection();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sidebarAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    if (_dashboardLayoutState == this) {
      _dashboardLayoutState = null;
    }
    _disableScreenProtection();
    _animationController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // FAB Actions
  // ===========================================================================

  void _onFabActionPressed(DashboardFabAction action) {
    final entityTypeState = ref.read(entityTypeProvider);
    final path = action.getPath(entityTypeState.currentType);

    if (path != null) {
      context.push(path);
    } else {
      logInfo('FAB action без пути: ${action.name}', tag: 'DashboardLayout');
    }
  }

  List<FABActionData> _buildFabActions(BuildContext context) {
    final entityTypeState = ref.read(entityTypeProvider);
    return DashboardFabAction.buildActions(
      context: context,
      entityType: entityTypeState.currentType,
      onActionPressed: _onFabActionPressed,
    );
  }

  // ===========================================================================
  // Sidebar Control (Public API)
  // ===========================================================================

  /// Закрыть sidebar
  void closeSidebar() {
    if (_animationController.value != 0.0) {
      _animationController.reverse();
    }
  }

  /// Открыть sidebar
  void openSidebar() {
    if (_animationController.value != 1.0) {
      _animationController.forward();
    }
  }

  /// Переключить состояние sidebar
  void toggleSidebar() {
    if (isSidebarOpen) {
      closeSidebar();
    } else {
      openSidebar();
    }
  }

  /// Проверить, открыт ли sidebar
  bool get isSidebarOpen => _animationController.value == 1.0;

  // ===========================================================================
  // Navigation
  // ===========================================================================

  void _onDestinationSelected(BuildContext context, int index) {
    _mobileFabKey.currentState?.close();

    final destination = DashboardDestination.fromIndex(index);
    if (!destination.opensSidebar) {
      closeSidebar();
    }

    context.go(destination.path);
  }

  // ===========================================================================
  // Animation Management
  // ===========================================================================

  /// Обновить состояние sidebar анимации на основе [DashboardRouteState]
  void _updateSidebarAnimation(DashboardRouteState routeState) {
    final previous = _previousRouteState;
    final shouldOpen = routeState.shouldOpenSidebar;

    // Определяем, нужно ли обновить анимацию
    final stateChanged =
        previous == null ||
        previous.selectedIndex != routeState.selectedIndex ||
        previous.shouldOpenSidebar != routeState.shouldOpenSidebar;

    // Проверяем закрытие sidebar route
    final sidebarClosed =
        previous != null &&
        previous.shouldOpenSidebar &&
        !routeState.shouldOpenSidebar &&
        routeState.selectedIndex == 0;

    if (stateChanged || sidebarClosed) {
      if (shouldOpen && _animationController.value != 1.0) {
        _animationController.forward();
      } else if (!shouldOpen && _animationController.value != 0.0) {
        _animationController.reverse();
      }
    }

    _previousRouteState = routeState;
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    ref.watch(entityTypeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final routeState = context.dashboardRouteState;
        final isDesktop = constraints.maxWidth >= 900;

        logTrace('Route state: $routeState', tag: 'DashboardLayout');

        // Обновляем анимацию sidebar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateSidebarAnimation(routeState);
        });

        if (isDesktop) {
          return _DesktopLayout(
            routeState: routeState,
            constraints: constraints,
            sidebarAnimation: _sidebarAnimation,
            fabKey: _fabKey,
            buildFabActions: _buildFabActions,
            onDestinationSelected: _onDestinationSelected,
            child: widget.child,
          );
        } else {
          return _MobileLayout(
            routeState: routeState,
            mobileFabKey: _mobileFabKey,
            buildFabActions: _buildFabActions,
            onDestinationSelected: _onDestinationSelected,
            child: widget.child,
          );
        }
      },
    );
  }
}

// =============================================================================
// Desktop Layout
// =============================================================================

class _DesktopLayout extends StatelessWidget {
  final DashboardRouteState routeState;
  final BoxConstraints constraints;
  final Animation<double> sidebarAnimation;
  final GlobalKey<ExpandableFABState> fabKey;
  final List<FABActionData> Function(BuildContext) buildFabActions;
  final void Function(BuildContext, int) onDestinationSelected;
  final Widget child;

  const _DesktopLayout({
    required this.routeState,
    required this.constraints,
    required this.sidebarAnimation,
    required this.fabKey,
    required this.buildFabActions,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // NavigationRail
          _buildNavigationRail(context),

          // Main content
          Expanded(
            flex: 1,
            child: routeState.isFullScreen
                ? child
                : const DashboardHomeScreen(),
          ),

          // Animated Sidebar
          _buildSidebar(context),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: NavigationRail(
        leadingAtTop: true,
        selectedIndex: routeState.selectedIndex,
        onDestinationSelected: (index) => onDestinationSelected(context, index),
        labelType: NavigationRailLabelType.selected,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpandableFAB(
            key: fabKey,
            direction: FABExpandDirection.rightDown,
            spacing: 56,
            isUseInNavigationRail: true,
            actions: buildFabActions(context),
          ),
        ),
        destinations: DashboardDestination.values
            .map((d) => d.toRailDestination())
            .toList(),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final showContent = routeState.shouldOpenSidebar;

    return AnimatedBuilder(
      animation: sidebarAnimation,
      builder: (context, _) {
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: sidebarAnimation.value,
            child: SizedBox(
              width: constraints.maxWidth / 2.15,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: AnimatedOpacity(
                  opacity: sidebarAnimation.value,
                  duration: const Duration(milliseconds: 150),
                  child: showContent ? child : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Mobile Layout
// =============================================================================

class _MobileLayout extends StatelessWidget {
  final DashboardRouteState routeState;
  final GlobalKey<ExpandableFABState> mobileFabKey;
  final List<FABActionData> Function(BuildContext) buildFabActions;
  final void Function(BuildContext, int) onDestinationSelected;
  final Widget child;

  const _MobileLayout({
    required this.routeState,
    required this.mobileFabKey,
    required this.buildFabActions,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final showBottomNav = !routeState.hideBottomNavigation;
    final showFab = !routeState.hideFAB;

    return Scaffold(
      body: child,
      bottomNavigationBar: showBottomNav
          ? _buildBottomNavigationBar(context)
          : null,
      floatingActionButton: showFab
          ? ExpandableFAB(
              key: mobileFabKey,
              direction: FABExpandDirection.up,
              spacing: 56,
              actions: buildFabActions(context),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final destinations = DashboardDestination.values;
    final homeIndex = DashboardDestination.home.index;
    final selectedIndex = routeState.selectedIndex;

    final leftDestinations = destinations.where((d) => d.index <= 1).toList();
    final rightDestinations = destinations.where((d) => d.index > 1).toList();

    return BottomAppBar(
      shape: const SmoothRoundedNotchedRectangle(
        guestCorner: Radius.circular(20),
        notchMargin: 4.0,
        s1: 18.0,
        s2: 18.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      height: 70,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // Left side
          ...leftDestinations.map(
            (d) => _BottomNavIconButton(
              destination: d,
              isSelected: selectedIndex == d.index,
              onTap: () => onDestinationSelected(context, d.index),
            ),
          ),
          // FAB space
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: selectedIndex == homeIndex ? 40 : 0,
            child: const SizedBox(width: 40),
          ),
          // Right side
          ...rightDestinations.map(
            (d) => _BottomNavIconButton(
              destination: d,
              isSelected: selectedIndex == d.index,
              onTap: () => onDestinationSelected(context, d.index),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bottom Nav Icon Button
// =============================================================================

class _BottomNavIconButton extends StatelessWidget {
  final DashboardDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavIconButton({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? destination.selectedIcon : destination.icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
