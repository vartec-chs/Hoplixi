import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/routing/paths.dart';

import 'dashboard_layout_constants.dart';
import 'desktop_dashboard_layout.dart';
import 'mobile_dashboard_layout.dart';
import 'screen_protection_wrapper.dart';

// =============================================================================
// Full Center Paths
// =============================================================================

/// Пути, которые должны отображаться в full-center режиме
const List<String> _fullCenterPaths = [AppRoutesPaths.notesGraph];

// =============================================================================
// DashboardLayout Widget
// =============================================================================

/// DashboardLayout — виджет-оболочка, управляющий навигацией
/// для password manager dashboard.
///
/// Автоматически переключается между mobile и desktop layout
/// в зависимости от размера экрана.
///
/// Контент (включая DashboardHomeScreen) определяется роутингом
/// и передаётся как [child].
class DashboardLayout extends StatelessWidget {
  /// Текущее состояние роутера
  final GoRouterState state;

  /// Контент из роутера (deepest matched route)
  final Widget child;

  const DashboardLayout({required this.state, required this.child, super.key});

  // ===========================================================================
  // Helpers
  // ===========================================================================

  String _currentEntity() {
    final ent = state.pathParameters['entity'];
    return (ent != null && EntityType.allTypesString.contains(ent))
        ? ent
        : EntityType.allTypesString.first;
  }

  bool _isFullCenter(String location) {
    return _fullCenterPaths.contains(location);
  }

  /// Проверяет, есть ли sub-маршрут панели (add, edit, view,
  /// categories, tags, icons, history и т.д.).
  ///
  /// На desktop используется для side-by-side режима:
  /// DashboardHomeScreen + правая панель.
  ///
  /// Примечание: full-center маршруты (graph) обрабатываются
  /// отдельно через [_isFullCenter] и имеют приоритет.
  bool _hasPanel(String location) {
    final segments = Uri.parse(location).pathSegments;
    return segments.length >= kMinPathSegmentsForPanel;
  }

  bool _shouldShowFAB(String location) {
    final segments = Uri.parse(location).pathSegments;
    if (segments.length == kPathSegmentsForEntity) {
      return true;
    }
    if (segments.length == kMinPathSegmentsForPanel &&
        kDashboardActions.contains(segments[2])) {
      return true;
    }
    return false;
  }

  bool _shouldShowBottomNav(String location) {
    final segments = Uri.parse(location).pathSegments;
    if (segments.length < kPathSegmentsForEntity) return false;
    if (segments.length == kPathSegmentsForEntity) return true;
    if (segments.length == kMinPathSegmentsForPanel &&
        kDashboardActions.contains(segments[2])) {
      return true;
    }
    return false;
  }

  int? _selectedRailIndex() {
    final location = state.uri.toString();
    final segments = Uri.parse(location).pathSegments;
    if (segments.length < kMinPathSegmentsForPanel) return kHomeIndex;
    final action = segments[2];
    switch (action) {
      case 'categories':
        return kCategoriesIndex;
      case 'tags':
        return kTagsIndex;
      case 'icons':
        return kIconsIndex;
      case 'graph':
        return kGraphIndex;
      default:
        return kHomeIndex;
    }
  }

  bool _isMobileLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width < MainConstants.kMobileBreakpoint;
  }

  String? _getCurrentAction() {
    final uri = state.uri.toString();
    final segments = Uri.parse(uri).pathSegments;
    if (segments.length >= kMinPathSegmentsForPanel) {
      return segments[2];
    }
    return null;
  }

  List<NavigationRailDestination> _getDestinations(String entity) {
    return entity == EntityType.note.id
        ? [...kBaseDestinations, kGraphDestination]
        : kBaseDestinations;
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final uri = state.uri.toString();
    final entity = _currentEntity();
    final isMobile = _isMobileLayout(context);
    final isFullCenter = _isFullCenter(uri);
    final destinations = _getDestinations(entity);

    void onNavItemSelected(int index) {
      final currentUri = state.uri.toString();
      String targetPath;

      if (index == kHomeIndex) {
        targetPath = '/dashboard/$entity';
      } else if (index >= kCategoriesIndex && index <= kIconsIndex) {
        targetPath = '/dashboard/$entity/${kDashboardActions[index - 1]}';
      } else if (index == kGraphIndex && entity == EntityType.note.id) {
        targetPath = AppRoutesPaths.notesGraph;
      } else {
        return;
      }

      if (currentUri == targetPath) return;
      context.go(targetPath);
    }

    final Widget layout;

    if (isMobile) {
      final showBottomNav = _shouldShowBottomNav(uri) && !isFullCenter;
      final showFAB = _shouldShowFAB(uri);

      layout = MobileDashboardLayout(
        entity: entity,
        uri: uri,
        showBottomNav: showBottomNav,
        showFAB: showFAB,
        currentAction: _getCurrentAction(),
        destinations: destinations,
        selectedIndex: _selectedRailIndex() ?? kHomeIndex,
        onNavItemSelected: onNavItemSelected,
        child: child,
      );
    } else {
      layout = DesktopDashboardLayout(
        entity: entity,
        uri: uri,
        hasPanel: _hasPanel(uri),
        isFullCenter: isFullCenter,
        destinations: destinations,
        selectedIndex: _selectedRailIndex(),
        onNavItemSelected: onNavItemSelected,
        child: child,
      );
    }

    return ScreenProtectionWrapper(child: layout);
  }
}
