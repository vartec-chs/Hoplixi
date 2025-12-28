import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/dashboard_destination.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/dashboard_fab_action.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/entity_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/expandable_fab.dart';
import 'package:hoplixi/routing/paths.dart';
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

/// Адаптивный layout для dashboard с использованием ShellRoute
/// На больших экранах: NavigationRail слева + main content + sidebar справа (child)
/// На маленьких экранах: BottomNavigationBar + main content, sidebar открывается по отдельным роутам
///
/// Используйте DashboardLayout.currentState для управления sidebar из любого места:
/// ```dart
/// // Закрыть sidebar
/// DashboardLayout.currentState?.closeSidebar();
///
/// // Открыть sidebar
/// DashboardLayout.currentState?.openSidebar();
///
/// // Переключить состояние sidebar
/// DashboardLayout.currentState?.toggleSidebar();
///
/// // Проверить, открыт ли sidebar
/// final isOpen = DashboardLayout.currentState?.isSidebarOpen ?? false;
/// ```
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
  int _previousIndex = 0;

  final GlobalKey<ExpandableFABState> _fabKey = GlobalKey();
  final GlobalKey<ExpandableFABState> _mobileFabKey = GlobalKey();

  void _preventScreenshotOn() async =>
      await ScreenProtector.protectDataLeakageOn();

  void _protectDataLeakageWithBlur() async =>
      await ScreenProtector.protectDataLeakageWithBlur();

  void _protectDataLeakageOff() async =>
      await ScreenProtector.protectDataLeakageOff();

  // Отслеживание предыдущего состояния sidebar
  bool _wasSidebarRoute = false;

  // ===========================================================================
  // FAB Actions Handler
  // ===========================================================================

  /// Обработчик действий FAB
  ///
  /// Централизованная обработка всех FAB actions через [DashboardFabAction]
  void _onFabActionPressed(DashboardFabAction action) {
    final entityTypeState = ref.read(entityTypeProvider);
    final entityType = entityTypeState.currentType;
    final path = action.getPath(entityType);

    if (path != null) {
      context.push(path);
    } else {
      // Для действий без пути — логируем и показываем TODO
      logInfo('FAB action без пути: ${action.name}', tag: 'DashboardLayout');
      debugPrint('TODO: Implement ${action.name}');
    }
  }

  /// Построить список действий FAB
  ///
  /// Использует [DashboardFabAction.buildActions] для генерации
  List<FABActionData> _buildFabActions(BuildContext context) {
    final entityTypeState = ref.read(entityTypeProvider);

    return DashboardFabAction.buildActions(
      context: context,
      entityType: entityTypeState.currentType,
      onActionPressed: _onFabActionPressed,
    );
  }

  @override
  void initState() {
    super.initState();
    // Регистрируем текущее состояние
    _dashboardLayoutState = this;
    
    if (UniversalPlatform.isMobile) {
      _preventScreenshotOn();
      _protectDataLeakageWithBlur();
    }
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
    // Очищаем ссылку на состояние
    if (_dashboardLayoutState == this) {
      _dashboardLayoutState = null;
    }
    
    if (UniversalPlatform.isMobile) {
      _protectDataLeakageOff();
    }

    _animationController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Navigation Helpers
  // ===========================================================================

  /// Получить индекс выбранного destination по текущему пути
  ///
  /// Использует [DashboardDestination.fromPath] для определения активного элемента.
  /// Если открыт sidebar route — возвращает индекс home (0), но sidebar открывается.
  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    // Если открыт sidebar route — остаёмся на home, sidebar откроется отдельно
    if (_shouldOpenSidebar(location)) {
      return DashboardDestination.home.index;
    }

    return DashboardDestination.fromPath(location).index;
  }

  /// Проверяет, должен ли путь открывать sidebar
  ///
  /// Использует [EntityTypeRouting.shouldOpenSidebar] для централизованной проверки.
  /// Sidebar открывается для:
  /// - Всех форм создания/редактирования
  /// - Дополнительных путей, определённых в [EntityTypeRouting._sidebarRoutes]
  bool _shouldOpenSidebar(String location) {
    return EntityTypeRouting.shouldOpenSidebar(location);
  }

  /// Публичный метод для закрытия sidebar
  /// Может быть вызван из любого места через dashboardSidebarKey
  void closeSidebar() {
    if (_animationController.value != 0.0) {
      _animationController.reverse();
    }
  }

  /// Публичный метод для открытия sidebar
  /// Может быть вызван из любого места через dashboardSidebarKey
  void openSidebar() {
    if (_animationController.value != 1.0) {
      _animationController.forward();
    }
  }

  /// Публичный метод для переключения состояния sidebar (открыт/закрыт)
  void toggleSidebar() {
    if (_animationController.value == 1.0) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  /// Проверяет, открыт ли sidebar в данный момент
  bool get isSidebarOpen => _animationController.value == 1.0;

  /// Обработчик выбора destination в навигации
  ///
  /// Использует [DashboardDestination.fromIndex] для получения пути навигации
  void _onDestinationSelected(BuildContext context, int index) {
    // Закрываем мобильный FAB при навигации
    _mobileFabKey.currentState?.close();

    final destination = DashboardDestination.fromIndex(index);

    // Если destination не открывает sidebar — закрываем его
    if (!destination.opensSidebar) {
      closeSidebar();
    }

    context.go(destination.path);
  }

  @override
  Widget build(BuildContext context) {
    // Следим за изменением текущего типа сущности
    ref.watch(entityTypeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final selectedIndex = _getSelectedIndex(context);
        final location = GoRouterState.of(context).uri.toString();
        final isSidebarRoute = _shouldOpenSidebar(location);

        // Управление анимацией при изменении выбранного индекса или маршрута
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Открываем sidebar если:
          // 1. selectedIndex > 0 (категории, иконки, теги)
          // 2. isSidebarRoute == true (любые формы и другие настроенные пути)
          final shouldOpenSidebar = selectedIndex > 0 || isSidebarRoute;

          // Проверяем, изменилось ли состояние
          final stateChanged = _previousIndex != selectedIndex;

          // Проверяем, закрылся ли sidebar route (был isSidebarRoute, а теперь нет)
          final sidebarClosed =
              _wasSidebarRoute && !isSidebarRoute && selectedIndex == 0;

          if (stateChanged || isSidebarRoute || sidebarClosed) {
            if (shouldOpenSidebar && _animationController.value != 1.0) {
              _animationController.forward();
            } else if (!shouldOpenSidebar &&
                _animationController.value != 0.0) {
              _animationController.reverse();
            }

            _previousIndex = selectedIndex;
          }

          // Сохраняем текущее состояние sidebar для следующего кадра
          _wasSidebarRoute = isSidebarRoute;
        });

        if (isDesktop) {
          return _buildDesktopLayout(
            context,
            constraints,
            selectedIndex,
            isSidebarRoute,
          );
        } else {
          return _buildMobileLayout(context, selectedIndex, isSidebarRoute);
        }
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    BoxConstraints constraints,
    int selectedIndex,
    bool isSidebarRoute,
  ) {
    final location = GoRouterState.of(context).uri.toString();
    logTrace('Current location: $location', tag: 'DashboardLayout');
    final isFullScreenRoute =
        location == AppRoutesPaths.dashboardNotesGraph ||
        location.startsWith('/dashboard/history/');

    return Scaffold(
      body: Row(
        children: [
          // NavigationRail слева
          _buildNavigationRail(context, selectedIndex),

          // Main content: DashboardHomeScreen или full screen route
          Expanded(
            flex: 1,
            child: isFullScreenRoute
                ? widget.child
                : const DashboardHomeScreen(),
          ),

          // Анимированный Sidebar справа
          AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: _sidebarAnimation.value,
                  child: SizedBox(
                    width: constraints.maxWidth / 2.15,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      // Показываем контент если:
                      // 1. selectedIndex != 0 (категории, иконки, теги)
                      // 2. isSidebarRoute == true (формы и другие настроенные пути)
                      child: AnimatedOpacity(
                        opacity: _sidebarAnimation.value,
                        duration: const Duration(milliseconds: 150),
                        child: (selectedIndex != 0 || isSidebarRoute)
                            ? widget.child
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    int selectedIndex,
    bool isSidebarRoute,
  ) {
    final location = GoRouterState.of(context).uri.toString();
    final isFullScreenRoute =
        location == AppRoutesPaths.dashboardNotesGraph ||
        location.startsWith('/dashboard/history/');

    return Scaffold(
      body: widget.child,
      // Скрываем BottomNavigationBar когда открыт sidebar route или full screen route
      bottomNavigationBar: isSidebarRoute || isFullScreenRoute
          ? null
          : _buildBottomNavigationBar(context, selectedIndex),
      // Скрываем FAB когда открыт sidebar route или full screen route
      floatingActionButton:
          (selectedIndex == 0 && !isSidebarRoute && !isFullScreenRoute)
          ? ExpandableFAB(
              key: _mobileFabKey,
              direction: FABExpandDirection.up,
              spacing: 56,
              actions: _buildFabActions(context),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ===========================================================================
  // UI Builders
  // ===========================================================================

  /// Построить NavigationRail для desktop
  ///
  /// Генерирует destinations из [DashboardDestination.values]
  Widget _buildNavigationRail(BuildContext context, int selectedIndex) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: NavigationRail(
        leadingAtTop: true,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        labelType: NavigationRailLabelType.selected,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpandableFAB(
            key: _fabKey,
            direction: FABExpandDirection.rightDown,
            spacing: 56,
            isUseInNavigationRail: true,
            actions: _buildFabActions(context),
          ),
        ),
        // Генерируем destinations из enum
        destinations: DashboardDestination.values
            .map((d) => d.toRailDestination())
            .toList(),
      ),
    );
  }

  /// Построить BottomAppBar для mobile
  ///
  /// Генерирует кнопки из [DashboardDestination.values]
  Widget _buildBottomNavigationBar(BuildContext context, int selectedIndex) {
    final destinations = DashboardDestination.values;
    final homeIndex = DashboardDestination.home.index;

    // Разделяем на левую и правую части для FAB notch
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
          // Левая часть (до FAB)
          ...leftDestinations.map(
            (d) => _buildBottomNavIconButton(
              context,
              destination: d,
              selectedIndex: selectedIndex,
            ),
          ),
          // Пространство для FAB (animated)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: selectedIndex == homeIndex ? 40 : 0,
            child: const SizedBox(width: 40),
          ),
          // Правая часть (после FAB)
          ...rightDestinations.map(
            (d) => _buildBottomNavIconButton(
              context,
              destination: d,
              selectedIndex: selectedIndex,
            ),
          ),
        ],
      ),
    );
  }

  /// Построить кнопку для BottomAppBar
  Widget _buildBottomNavIconButton(
    BuildContext context, {
    required DashboardDestination destination,
    required int selectedIndex,
  }) {
    final isSelected = selectedIndex == destination.index;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _onDestinationSelected(context, destination.index),
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
