import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/routing/paths.dart';

import 'dashboard_layout_constants.dart';
import 'desktop_dashboard_layout.dart';
import 'mobile_dashboard_layout.dart';

// =============================================================================
// Full Center Paths
// =============================================================================

/// Пути, которые должны отображаться в full-center режиме
const List<String> _fullCenterPaths = [AppRoutesPaths.notesGraph];

// =============================================================================
// DashboardLayout Widget
// =============================================================================

/// DashboardLayout — stateful виджет, управляющий навигацией и анимациями
/// для password manager dashboard.
///
/// Автоматически переключается между mobile и desktop layout
/// в зависимости от размера экрана.
class DashboardLayout extends StatefulWidget {
  /// Текущее состояние роутера
  final GoRouterState state;

  /// Контент панели (deepest matched route)
  final Widget panelChild;

  const DashboardLayout({
    required this.state,
    required this.panelChild,
    super.key,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _wasPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kPanelAnimationDuration,
    );

    final uri = widget.state.uri.toString();
    final hasPanel = _hasPanel(uri);
    final isFullCenter = _isFullCenter(uri);
    if (hasPanel && !isFullCenter) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant DashboardLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    final uri = widget.state.uri.toString();
    final hasPanel = _hasPanel(uri);
    final isFullCenter = _isFullCenter(uri);

    // Если full-center — обязательно закрываем панель
    if (isFullCenter) {
      if (_controller.status == AnimationStatus.forward ||
          _controller.value > 0.0) {
        _controller.reverse();
      }
      _wasPanelOpen = false;
      return;
    }

    // Обычная логика для панели
    if (hasPanel && !_wasPanelOpen) {
      _controller.forward();
    } else if (!hasPanel && _wasPanelOpen) {
      _controller.reverse();
    }
    _wasPanelOpen = hasPanel;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  String _currentEntity() {
    final ent = widget.state.pathParameters['entity'];
    return (ent != null && EntityType.allTypesString.contains(ent))
        ? ent
        : EntityType.allTypesString.first;
  }

  bool _hasPanel(String location) {
    final segments = Uri.parse(location).pathSegments;
    return segments.length >= kMinPathSegmentsForPanel;
  }

  bool _isFullCenter(String location) {
    return _fullCenterPaths.contains(location);
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
    final location = widget.state.uri.toString();
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
    final uri = widget.state.uri.toString();
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
  // Navigation Callbacks
  // ===========================================================================

  void _onNavItemSelected(String entity, int index) {
    if (index == kHomeIndex) {
      context.go('/dashboard/$entity');
    } else if (index >= kCategoriesIndex && index <= kIconsIndex) {
      context.go('/dashboard/$entity/${kDashboardActions[index - 1]}');
    } else if (index == kGraphIndex && entity == EntityType.note.id) {
      context.go(AppRoutesPaths.notesGraph);
    }
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final uri = widget.state.uri.toString();
    final entity = _currentEntity();
    final isMobile = _isMobileLayout(context);
    final hasPanel = _hasPanel(uri);
    final isFullCenter = _isFullCenter(uri);
    final destinations = _getDestinations(entity);

    if (isMobile) {
      final showPanel = hasPanel || isFullCenter;
      final showBottomNav = _shouldShowBottomNav(uri) && !isFullCenter;
      final showFAB = _shouldShowFAB(uri);

      return MobileDashboardLayout(
        entity: entity,
        uri: uri,
        panelChild: widget.panelChild,
        showPanel: showPanel,
        showBottomNav: showBottomNav,
        showFAB: showFAB,
        currentAction: _getCurrentAction(),
        destinations: destinations,
        selectedIndex: _selectedRailIndex() ?? kHomeIndex,
        onNavItemSelected: (index) => _onNavItemSelected(entity, index),
      );
    }

    return DesktopDashboardLayout(
      entity: entity,
      uri: uri,
      panelChild: widget.panelChild,
      hasPanel: hasPanel,
      isFullCenter: isFullCenter,
      destinations: destinations,
      selectedIndex: _selectedRailIndex(),
      onNavItemSelected: (index) => _onNavItemSelected(entity, index),
      panelAnimation: _controller,
    );
  }
}
