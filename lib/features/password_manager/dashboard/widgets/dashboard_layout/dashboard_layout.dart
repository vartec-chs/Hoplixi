import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/screen_protection_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/dashboard_drawer.dart';
import 'package:hoplixi/features/settings/providers/settings_prefs_providers.dart';
import 'package:hoplixi/routing/paths.dart';

import 'config/dashboard_layout_constants.dart';
import 'dashboard_drawer_scope.dart';
import 'desktop_three_column_layout.dart';
import 'keyboard_shortcuts.dart';
import 'widgets/fab_builder.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/mobile_cloud_sync_overlay.dart';

const List<String> _fullCenterPaths = [AppRoutesPaths.notesGraph];
const double _floatingNavScrimExtraHeight = 56.0;

class AppNavigationShell extends StatefulWidget {
  final GoRouterState state;
  final Widget child;

  const AppNavigationShell({
    required this.state,
    required this.child,
    super.key,
  });

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  final GlobalKey<ScaffoldState> _mobileScaffoldKey =
      GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;

  String _currentEntity() {
    final ent = widget.state.pathParameters['entity'];
    return (ent != null && EntityType.allTypesString.contains(ent))
        ? ent
        : EntityType.allTypesString.first;
  }

  bool _isFullCenter(String location) => _fullCenterPaths.contains(location);

  bool _isBaseRoute(String location) {
    final segments = Uri.parse(location).pathSegments;
    return segments.length == kPathSegmentsForEntity;
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
    if (_isFullCenter(location)) return false;

    final segments = Uri.parse(location).pathSegments;
    if (segments.length < kPathSegmentsForEntity) return false;
    if (segments.length == kPathSegmentsForEntity) return true;
    if (segments.length == kMinPathSegmentsForPanel &&
        kDashboardActions.contains(segments[2])) {
      return true;
    }
    return false;
  }

  int _selectedRailIndex(String location) {
    final segments = Uri.parse(location).pathSegments;
    if (segments.length < kMinPathSegmentsForPanel) return kHomeIndex;

    switch (segments[2]) {
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

  String? _currentAction(String location) {
    final segments = Uri.parse(location).pathSegments;
    if (segments.length >= kMinPathSegmentsForPanel) {
      return segments[2];
    }
    return null;
  }

  List<NavigationRailDestination> _destinations(String entity) {
    return entity == EntityType.note.id
        ? [...kBaseDestinations, kGraphDestination]
        : kBaseDestinations;
  }

  void _openDrawer() {
    _mobileScaffoldKey.currentState?.openDrawer();
  }

  void _onNavItemSelected(BuildContext context, int index, String entity) {
    final currentUri = widget.state.uri.toString();
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

  void _handleGoBack(String entity) {
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/dashboard/$entity');
  }

  void _handleCreateEntity(String entity) {
    if (!context.mounted) return;
    context.go('/dashboard/$entity/add');
  }

  void _handleOpenTags(String entity) {
    if (!context.mounted) return;
    context.go('/dashboard/$entity/tags');
  }

  void _handleOpenCategories(String entity) {
    if (!context.mounted) return;
    context.go('/dashboard/$entity/categories');
  }

  void _handleOpenIcons(String entity) {
    if (!context.mounted) return;
    context.go('/dashboard/$entity/icons');
  }

  Widget _buildMobileShell(
    BuildContext context, {
    required String entity,
    required String location,
    required int currentIndex,
    required List<NavigationRailDestination> destinations,
    required bool floatingNavEffectsEnabled,
  }) {
    final showBottomNav = _shouldShowBottomNav(location);
    final showFAB = _shouldShowFAB(location);
    final entityType = EntityType.fromId(entity) ?? EntityType.password;
    final systemPadding = MediaQuery.of(context).viewPadding;
    final navBottom = systemPadding.bottom + 12;
    final navScrimHeight =
        navBottom + kFloatingNavBarHeight + _floatingNavScrimExtraHeight;
    final fabBottom = showBottomNav
        ? systemPadding.bottom +
              kFloatingNavBarHeight +
              kFloatingNavFabBottomOffset +
              10
        : systemPadding.bottom + kFloatingNavFabBottomOffset;

    return DashboardDrawerScope(
      openDrawer: _openDrawer,
      child: Stack(
        children: [
          Positioned.fill(
            child: KeyedSubtree(key: ValueKey(location), child: widget.child),
          ),
          if (floatingNavEffectsEnabled)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: navScrimHeight,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: showBottomNav ? 1.0 : 0.0,
                  duration: kFadeAnimationDuration,
                  curve: Curves.easeInOut,
                  child: const _FloatingNavBarScrim(),
                ),
              ),
            ),
          Positioned(
            left: kFloatingNavMarginHorizontal,
            right: kFloatingNavMarginHorizontal,
            bottom: navBottom,
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
                      selectedIndex: currentIndex,
                      visualEffectsEnabled: floatingNavEffectsEnabled,
                      onItemSelected: (index) =>
                          _onNavItemSelected(context, index, entity),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            right: kFloatingNavMarginHorizontal,
            bottom: fabBottom,
            duration: kScaleAnimationDuration,
            curve: showBottomNav ? Curves.easeOutCubic : Curves.easeInCubic,
            child: IgnorePointer(
              ignoring: !showFAB,
              child: AnimatedSlide(
                offset: showFAB ? Offset.zero : const Offset(0, 1.5),
                duration: kScaleAnimationDuration,
                curve: showFAB ? Curves.easeOutCubic : Curves.easeInCubic,
                child: AnimatedOpacity(
                  opacity: showFAB ? 1.0 : 0.0,
                  duration: kFadeAnimationDuration,
                  curve: Curves.easeInOut,
                  child: AnimatedScale(
                    scale: showFAB ? 1.0 : 0.95,
                    duration: kScaleAnimationDuration,
                    curve: showFAB ? Curves.easeOutBack : Curves.easeIn,
                    child: DashboardFabBuilder(
                      context: context,
                      entity: entity,
                      currentAction: _currentAction(location),
                      isMobile: true,
                    ).buildExpandableFAB(),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isDrawerOpen,
              child: Scaffold(
                key: _mobileScaffoldKey,
                backgroundColor: Colors.transparent,
                onDrawerChanged: (isOpen) {
                  setState(() => _isDrawerOpen = isOpen);
                },
                drawer: DashboardDrawer(entityType: entityType),
                body: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopShell(
    BuildContext context, {
    required String entity,
    required String location,
    required int currentIndex,
    required List<NavigationRailDestination> destinations,
  }) {
    final theme = Theme.of(context);
    final entityType = EntityType.fromId(entity) ?? EntityType.password;
    final shellChild = _isFullCenter(location)
        ? widget.child
        : DesktopThreeColumnLayout(
            entityType: entityType,
            panelIdentity: location,
            rightPanel: _isBaseRoute(location) ? null : widget.child,
          );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        kShortcutGoBack: () => _handleGoBack(entity),
        kShortcutCreateEntity: () => _handleCreateEntity(entity),
        kShortcutOpenTags: () => _handleOpenTags(entity),
        kShortcutOpenCategories: () => _handleOpenCategories(entity),
        kShortcutOpenIcons: () => _handleOpenIcons(entity),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: kNavigationRailWidth,
                child: NavigationRail(
                  unselectedIconTheme: IconThemeData(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                  selectedIconTheme: IconThemeData(
                    color: theme.colorScheme.onPrimary,
                  ),
                  selectedLabelTextStyle: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w400,
                  ),
                  indicatorColor: theme.colorScheme.primaryContainer,
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kIndicatorBorderRadius),
                  ),
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) =>
                      _onNavItemSelected(context, index, entity),
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: DashboardFabBuilder(
                      context: context,
                      entity: entity,
                      currentAction: null,
                      isMobile: false,
                    ).buildExpandableFAB(),
                  ),
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: shellChild),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.state.uri.toString();
    final entity = _currentEntity();
    final currentIndex = _selectedRailIndex(location);
    final destinations = _destinations(entity);
    final isMobile =
        MediaQuery.sizeOf(context).width < MainConstants.kMobileBreakpoint;

    return Consumer(
      builder: (context, ref, child) {
        ref.watch(dashboardScreenProtectionProvider);
        final floatingNavEffectsEnabled =
            ref.watch(dashboardFloatingNavEffectsEnabledProvider).value ?? true;
        final shell = isMobile
            ? _buildMobileShell(
                context,
                entity: entity,
                location: location,
                currentIndex: currentIndex,
                destinations: destinations,
                floatingNavEffectsEnabled: floatingNavEffectsEnabled,
              )
            : _buildDesktopShell(
                context,
                entity: entity,
                location: location,
                currentIndex: currentIndex,
                destinations: destinations,
              );

        return Stack(
          children: [
            Positioned.fill(child: shell),
            const Positioned.fill(child: MobileCloudSyncOverlay()),
          ],
        );
      },
    );
  }
}

class _FloatingNavBarScrim extends StatelessWidget {
  const _FloatingNavBarScrim();

  @override
  Widget build(BuildContext context) {
    final shadowColor = Theme.of(context).primaryColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            shadowColor.withValues(alpha: 0.24),
            shadowColor.withValues(alpha: 0.14),
            shadowColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
