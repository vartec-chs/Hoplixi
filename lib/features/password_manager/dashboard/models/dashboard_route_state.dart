import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/dashboard_destination.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/routing/paths.dart';

// =============================================================================
// Dashboard Route State
// =============================================================================

/// Централизованное управление состоянием маршрутов Dashboard.
///
/// Позволяет легко определять и расширять:
/// - Full-screen маршруты (скрывают navigation и FAB)
/// - Sidebar маршруты (открывают боковую панель)
///
/// ## Использование
///
/// ```dart
/// // В виджете
/// final routeState = DashboardRouteState.fromContext(context);
///
/// // Или напрямую
/// final routeState = DashboardRouteState.fromLocation('/dashboard/notes-graph');
///
/// // Проверки
/// if (routeState.isFullScreen) { /* скрыть навигацию */ }
/// if (routeState.shouldOpenSidebar) { /* открыть sidebar */ }
/// ```
///
/// ## Добавление новых маршрутов
///
/// Для full-screen маршрутов добавьте в [_fullScreenRoutes] или [_fullScreenPrefixes].
/// Для sidebar маршрутов добавьте в [_sidebarRoutes] или [_sidebarPrefixes].
@immutable
class DashboardRouteState {
  /// Текущий путь маршрута
  final String location;

  /// Является ли маршрут full-screen (скрывает navigation bar и FAB)
  final bool isFullScreen;

  /// Должен ли маршрут открывать sidebar
  final bool shouldOpenSidebar;

  /// Является ли маршрут формой (создание/редактирование сущности)
  final bool isFormRoute;

  /// Индекс выбранного destination в навигации
  final int selectedIndex;

  /// Тип сущности, если это form route
  final EntityType? entityType;

  const DashboardRouteState._({
    required this.location,
    required this.isFullScreen,
    required this.shouldOpenSidebar,
    required this.isFormRoute,
    required this.selectedIndex,
    this.entityType,
  });

  // ===========================================================================
  // Full-Screen Routes Configuration
  // ===========================================================================

  /// Точные пути full-screen маршрутов.
  ///
  /// Маршруты в этом списке будут полностью скрывать:
  /// - NavigationRail/BottomNavigationBar
  /// - FAB
  ///
  /// Добавляйте сюда статические пути без параметров.
  static const Set<String> _fullScreenRoutes = {
    AppRoutesPaths.dashboardNotesGraph,
    // Добавьте новые full-screen маршруты здесь:
    // AppRoutesPaths.dashboardSomeFullScreenPage,
  };

  /// Префиксы путей full-screen маршрутов.
  ///
  /// Все пути, начинающиеся с этих префиксов, будут full-screen.
  /// Используйте для динамических маршрутов с параметрами.
  static const Set<String> _fullScreenPrefixes = {
    '/dashboard/history/',
    // Добавьте новые префиксы здесь:
    // '/dashboard/some-dynamic-screen/',
  };

  // ===========================================================================
  // Sidebar Routes Configuration
  // ===========================================================================

  /// Точные пути sidebar маршрутов.
  ///
  /// Маршруты в этом списке будут открывать боковую панель.
  /// Добавляйте сюда статические пути без параметров.
  static const Set<String> _sidebarRoutes = {
    AppRoutesPaths.dashboardMigrateOtp,
    AppRoutesPaths.dashboardMigratePasswords,
    // Добавьте новые sidebar маршруты здесь:
    // AppRoutesPaths.dashboardSomeSidebarPage,
  };

  /// Префиксы путей sidebar маршрутов.
  ///
  /// Все пути, начинающиеся с этих префиксов, будут открывать sidebar.
  /// Используйте для динамических маршрутов с параметрами.
  static const Set<String> _sidebarPrefixes = {
    // Добавьте новые префиксы здесь:
    // '/dashboard/detail/',
  };

  // ===========================================================================
  // Factory Constructors
  // ===========================================================================

  /// Создать из BuildContext.
  ///
  /// Автоматически получает текущий путь из GoRouter.
  factory DashboardRouteState.fromContext(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return DashboardRouteState.fromLocation(location);
  }

  /// Создать из строки пути.
  factory DashboardRouteState.fromLocation(String location) {
    final isFullScreen = _checkFullScreen(location);
    final isFormRoute = EntityTypeRouting.isAnyFormRoute(location);
    final isSidebarRoute = _checkSidebarRoute(location);
    final entityType = EntityTypeRouting.fromFormRoute(location);

    // Определяем индекс destination
    final selectedIndex = _calculateSelectedIndex(
      location: location,
      isSidebarRoute: isSidebarRoute || isFormRoute,
    );

    // Sidebar открывается если:
    // 1. selectedIndex > 0 (не home)
    // 2. Это sidebar route
    // 3. Это form route
    final shouldOpenSidebar =
        selectedIndex > 0 || isSidebarRoute || isFormRoute;

    return DashboardRouteState._(
      location: location,
      isFullScreen: isFullScreen,
      shouldOpenSidebar: shouldOpenSidebar,
      isFormRoute: isFormRoute,
      selectedIndex: selectedIndex,
      entityType: entityType,
    );
  }

  // ===========================================================================
  // Private Helpers
  // ===========================================================================

  /// Проверить, является ли маршрут full-screen
  static bool _checkFullScreen(String location) {
    // Проверяем точные совпадения
    if (_fullScreenRoutes.contains(location)) {
      return true;
    }

    // Проверяем префиксы
    for (final prefix in _fullScreenPrefixes) {
      if (location.startsWith(prefix)) {
        return true;
      }
    }

    return false;
  }

  /// Проверить, является ли маршрут sidebar route (не считая form routes)
  static bool _checkSidebarRoute(String location) {
    // Проверяем точные совпадения
    if (_sidebarRoutes.contains(location)) {
      return true;
    }

    // Проверяем префиксы
    for (final prefix in _sidebarPrefixes) {
      if (location.startsWith(prefix)) {
        return true;
      }
    }

    return false;
  }

  /// Вычислить индекс выбранного destination
  static int _calculateSelectedIndex({
    required String location,
    required bool isSidebarRoute,
  }) {
    // Если это sidebar route (форма или явный sidebar) —
    // остаёмся на home, sidebar откроется отдельно
    if (isSidebarRoute) {
      return DashboardDestination.home.index;
    }

    return DashboardDestination.fromPath(location).index;
  }

  // ===========================================================================
  // Public Static Helpers
  // ===========================================================================

  /// Проверить, является ли путь full-screen маршрутом.
  ///
  /// Статический метод для использования без создания экземпляра.
  static bool isFullScreenRoute(String location) => _checkFullScreen(location);

  /// Проверить, должен ли путь открывать sidebar.
  ///
  /// Статический метод для использования без создания экземпляра.
  /// Учитывает как явные sidebar routes, так и form routes.
  static bool isSidebarRoute(String location) {
    return _checkSidebarRoute(location) ||
        EntityTypeRouting.isAnyFormRoute(location);
  }

  /// Зарегистрировать full-screen маршрут в runtime.
  ///
  /// **Важно:** Используйте только для динамической регистрации.
  /// Для постоянных маршрутов добавляйте их в [_fullScreenRoutes].
  static void registerFullScreenRoute(String route) {
    _dynamicFullScreenRoutes.add(route);
  }

  /// Зарегистрировать sidebar маршрут в runtime.
  ///
  /// **Важно:** Используйте только для динамической регистрации.
  /// Для постоянных маршрутов добавляйте их в [_sidebarRoutes].
  static void registerSidebarRoute(String route) {
    _dynamicSidebarRoutes.add(route);
  }

  /// Удалить динамически зарегистрированный full-screen маршрут
  static void unregisterFullScreenRoute(String route) {
    _dynamicFullScreenRoutes.remove(route);
  }

  /// Удалить динамически зарегистрированный sidebar маршрут
  static void unregisterSidebarRoute(String route) {
    _dynamicSidebarRoutes.remove(route);
  }

  /// Динамически зарегистрированные full-screen маршруты
  static final Set<String> _dynamicFullScreenRoutes = {};

  /// Динамически зарегистрированные sidebar маршруты
  static final Set<String> _dynamicSidebarRoutes = {};

  // ===========================================================================
  // Computed Properties
  // ===========================================================================

  /// Должен ли скрываться BottomNavigationBar
  bool get hideBottomNavigation => isFullScreen || shouldOpenSidebar;

  /// Должен ли скрываться FAB
  bool get hideFAB => isFullScreen || shouldOpenSidebar || selectedIndex != 0;

  /// Является ли это home screen без открытого sidebar
  bool get isHomeScreen => selectedIndex == 0 && !shouldOpenSidebar;

  @override
  String toString() {
    return 'DashboardRouteState('
        'location: $location, '
        'isFullScreen: $isFullScreen, '
        'shouldOpenSidebar: $shouldOpenSidebar, '
        'isFormRoute: $isFormRoute, '
        'selectedIndex: $selectedIndex, '
        'entityType: $entityType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardRouteState &&
        other.location == location &&
        other.isFullScreen == isFullScreen &&
        other.shouldOpenSidebar == shouldOpenSidebar &&
        other.isFormRoute == isFormRoute &&
        other.selectedIndex == selectedIndex &&
        other.entityType == entityType;
  }

  @override
  int get hashCode {
    return Object.hash(
      location,
      isFullScreen,
      shouldOpenSidebar,
      isFormRoute,
      selectedIndex,
      entityType,
    );
  }
}

// =============================================================================
// Route State Extension for BuildContext
// =============================================================================

/// Extension для удобного доступа к DashboardRouteState через BuildContext.
extension DashboardRouteStateX on BuildContext {
  /// Получить текущее состояние маршрута Dashboard.
  ///
  /// ```dart
  /// final routeState = context.dashboardRouteState;
  /// if (routeState.isFullScreen) { ... }
  /// ```
  DashboardRouteState get dashboardRouteState =>
      DashboardRouteState.fromContext(this);
}
