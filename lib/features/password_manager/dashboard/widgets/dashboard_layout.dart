import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/expandable_fab.dart';
import 'package:hoplixi/routing/paths.dart';

// ===========================================================================
// Constants
// ===========================================================================

// Animation durations
const Duration kPanelAnimationDuration = Duration(milliseconds: 280);
const Duration kFadeAnimationDuration = Duration(milliseconds: 250);
const Duration kScaleAnimationDuration = Duration(milliseconds: 300);
const Duration kOpacityAnimationDuration = Duration(milliseconds: 150);

// Screen breakpoints
const double kMobileBreakpoint = 700.0;
const double kDesktopBreakpoint = 1000.0;

// Layout dimensions
const double kRailWidth = 80.0;
const double kLeftPanelWidth = 260.0;
const double kDividerWidth = 2.0;
const double kBottomNavHeight = 70.0;
const double kFabSpaceWidth = 40.0;
const double kIndicatorBorderRadius = 16.0;
const double kBottomNavBorderRadius = 12.0;
const double kBottomNavFontSize = 12.0;
const double kBottomNavSpacing = 4.0;
const double kBottomNavPaddingHorizontal = 8.0;
const double kBottomNavPaddingVertical = 4.0;

// Animation values
const double kCenterScaleWhenPanelOpen = 0.92;
const double kCenterScaleWhenFullCenter = 0.96;
const double kPanelZoomBegin = 0.85;
const double kPanelZoomEnd = 1.0;
const double kFadeBegin = 0.0;
const double kFadeEnd = 1.0;
const double kFullCenterScaleBegin = 0.92;
const double kFullCenterScaleOffset = 0.08;

// Path segments
const int kMinPathSegmentsForPanel = 3;
const int kPathSegmentsForEntity = 2;

// Navigation indices
const int kHomeIndex = 0;
const int kCategoriesIndex = 1;
const int kTagsIndex = 2;
const int kIconsIndex = 3;
const int kGraphIndex = 4;

// Bottom navigation
const double kBottomNavNotchMargin = 8.0;

// Animation intervals
const double kFadeAnimationIntervalStart = 0.1;
const double kFadeAnimationIntervalEnd = 0.4;

// ===========================================================================
// Widget
// ===========================================================================

// В теле класса _DashboardLayoutState добавьте:
const List<String> _fullCenterPaths = [
  AppRoutesPaths.notesGraph,
]; // сюда можно добавить другие full-center имена

/// Действия панели справа и нижнего меню
const List<String> actions = ['categories', 'tags', 'icons'];

/// DashboardLayout — stateful, хранит navigatorKeys для каждой entity и анимацию панели
class DashboardLayout extends StatefulWidget {
  final GoRouterState state;
  final Widget
  panelChild; // deepest matched route (если это panel), иначе SizedBox

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

  // Кэшированные destinations для NavigationRail
  static const List<NavigationRailDestination> _baseDestinations = [
    NavigationRailDestination(icon: Icon(Icons.home), label: Text('Главная')),
    NavigationRailDestination(
      icon: Icon(Icons.category),
      label: Text('Категории'),
    ),
    NavigationRailDestination(icon: Icon(Icons.tag), label: Text('Теги')),
    NavigationRailDestination(icon: Icon(Icons.image), label: Text('Иконки')),
  ];

  static const NavigationRailDestination _graphDestination =
      NavigationRailDestination(
        icon: Icon(Icons.bubble_chart),
        label: Text('Граф'),
      );

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
  // FAB Actions (принцип из старого DashboardLayout)
  // ===========================================================================

  /// Построить список действий FAB для текущей entity
  List<FABActionData> _buildFabActions(String entity, BuildContext context) {
    final theme = Theme.of(context);
    return [
      FABActionData(
        icon: Icons.add,
        label: 'Добавить',
        onPressed: () => _onFabActionPressed(entity, 'add'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      FABActionData(
        icon: Icons.category,
        label: 'Категории',
        onPressed: () => _onFabActionPressed(entity, 'categories'),
      ),
      FABActionData(
        icon: Icons.tag,
        label: 'Теги',
        onPressed: () => _onFabActionPressed(entity, 'tags'),
      ),
      FABActionData(
        icon: Icons.image,
        label: 'Иконки',
        onPressed: () => _onFabActionPressed(entity, 'icons'),
      ),
    ];
  }

  /// Обработать нажатие на FAB action
  void _onFabActionPressed(String entity, String action) {
    final path = '/dashboard/$entity/$action';
    if (context.mounted) {
      context.go(path);
    }
  }

  // ===========================================================================
  // Bottom Navigation Bar
  // ===========================================================================

  /// Построить BottomNavigationBar для мобильных устройств
  BottomAppBar _buildBottomNavigationBar(
    String entity,
    List<NavigationRailDestination> destinations,
  ) {
    final currentIndex = _selectedRailIndex() ?? 0;

    final leftDestinations = destinations
        .where((d) => d == destinations[0] || d == destinations[1])
        .toList();
    final rightDestinations = destinations
        .where((d) => destinations.indexOf(d) > 1)
        .toList();

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: kBottomNavNotchMargin,
      padding: const EdgeInsets.symmetric(
        horizontal: kBottomNavPaddingHorizontal,
        vertical: kBottomNavPaddingVertical,
      ),
      height: kBottomNavHeight,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // Left side
          ...leftDestinations.map(
            (d) => _BottomNavIconButton(
              destination: d,
              isSelected: currentIndex == destinations.indexOf(d),
              onTap: () =>
                  _onBottomNavItemSelected(entity, destinations.indexOf(d)),
            ),
          ),
          // FAB space
          AnimatedContainer(
            duration: kScaleAnimationDuration,
            curve: Curves.easeInOut,
            width: currentIndex == kHomeIndex ? kFabSpaceWidth : 0,
            child: const SizedBox(width: kFabSpaceWidth),
          ),
          // Right side
          ...rightDestinations.map(
            (d) => _BottomNavIconButton(
              destination: d,
              isSelected: currentIndex == destinations.indexOf(d),
              onTap: () =>
                  _onBottomNavItemSelected(entity, destinations.indexOf(d)),
            ),
          ),
        ],
      ),
    );
  }

  /// Обработать нажатие на пункт BottomNavigationBar
  void _onBottomNavItemSelected(String entity, int index) {
    if (index == kHomeIndex) {
      // home: close panel
      context.go('/dashboard/$entity');
    } else if (index >= kCategoriesIndex && index <= kIconsIndex) {
      context.go('/dashboard/$entity/${actions[index - 1]}');
    } else if (index == kGraphIndex && entity == EntityType.note.id) {
      context.go(AppRoutesPaths.notesGraph);
    }
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
    // считаем, что панель открыта когда путь имеет третий сегмент:
    // /dashboard/<entity>/<panel-or-action>
    final segments = Uri.parse(location).pathSegments;
    return segments.length >= kMinPathSegmentsForPanel;
  }

  bool _isFullCenter(String location) {
    return _fullCenterPaths.contains(location);
  }

  // Проверяем, нужно ли показывать FAB (только на 2-сегментных путях)
  bool _shouldShowFAB(String location) {
    final segments = Uri.parse(location).pathSegments;
    return segments.length == kPathSegmentsForEntity; // /dashboard/entity
  }

  // Проверяем, нужно ли показывать BottomNavigationBar на мобильных устройствах
  bool _shouldShowBottomNav(String location) {
    final segments = Uri.parse(location).pathSegments;
    if (segments.length < kPathSegmentsForEntity) return false;
    if (segments.length == kPathSegmentsForEntity)
      return true; // /dashboard/:entity
    if (segments.length == kMinPathSegmentsForPanel &&
        actions.contains(segments[2])) {
      return true; // /dashboard/:entity/action
    }
    return false;
  }

  int? _selectedRailIndex() {
    final location = widget.state.uri.toString();
    final segments = Uri.parse(location).pathSegments;
    if (segments.length < kMinPathSegmentsForPanel) return kHomeIndex; // home
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

  @override
  Widget build(BuildContext context) {
    final uri = widget.state.uri.toString();
    final entity = _currentEntity();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < kMobileBreakpoint;
    final showDrawerAsPanel =
        screenWidth >=
        kDesktopBreakpoint; // Показывать drawer как панель для больших экранов
    final hasPanel = _hasPanel(uri);
    final panel = hasPanel ? widget.panelChild : const SizedBox.shrink();
    final isFullCenter = _isFullCenter(uri);

    // Используем кэшированные destinations, добавляя Graph только для notes
    final destinations = entity == EntityType.note.id
        ? [..._baseDestinations, _graphDestination]
        : _baseDestinations;

    // Mobile: единый layout с Stack и взаимной анимацией центра и панели
    if (isMobile) {
      final showPanel = hasPanel || isFullCenter;

      return Scaffold(
        body: Stack(
          children: [
            // Центр: DashboardHomeScreen с обратной анимацией (fade + scale down)
            AnimatedOpacity(
              opacity: showPanel ? 0.0 : 1.0,
              duration: kFadeAnimationDuration,
              curve: showPanel ? Curves.easeOut : Curves.easeIn,
              child: AnimatedScale(
                scale: showPanel ? kCenterScaleWhenPanelOpen : 1.0,
                duration: kScaleAnimationDuration,
                curve: Curves.easeInOut,
                child: IgnorePointer(
                  ignoring: showPanel, // отключаем взаимодействие когда скрыт
                  child: RepaintBoundary(
                    child: DashboardHomeScreen(
                      entityType: EntityType.fromId(entity)!,
                      showDrawerButton: !showDrawerAsPanel,
                    ),
                  ),
                ),
              ),
            ),

            // Анимированная панель поверх центра (ZoomPageTransitionsBuilder стиль)
            AnimatedSwitcher(
              duration: kScaleAnimationDuration,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                // Zoom in/out анимация как в ZoomPageTransitionsBuilder
                final scaleAnimation =
                    Tween<double>(
                      begin: kPanelZoomBegin,
                      end: kPanelZoomEnd,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
                      ),
                    );

                final fadeAnimation =
                    Tween<double>(begin: kFadeBegin, end: kFadeEnd).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: const Interval(
                          kFadeAnimationIntervalStart,
                          kFadeAnimationIntervalEnd,
                          curve: Curves.easeOut,
                        ),
                      ),
                    );

                return ScaleTransition(
                  scale: scaleAnimation,
                  child: FadeTransition(opacity: fadeAnimation, child: child),
                );
              },
              child: showPanel
                  ? Container(
                      key: const ValueKey('panel'),
                      child: widget.panelChild,
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
        bottomNavigationBar: (_shouldShowBottomNav(uri) && !isFullCenter)
            ? _buildBottomNavigationBar(entity, destinations)
            : null,
        floatingActionButton: (_shouldShowFAB(uri) && !showPanel)
            ? _buildExpandableFAB(entity, isMobile)
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    }

    // Desktop/tablet: трёхколоночный layout с animated panel
    return Scaffold(
      // appBar: AppBar(title: Text('${GoRouter.of(context).state.uri}')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // NavigationRail / left menu для categories, tags, icons
              NavigationRail(
                unselectedIconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
                selectedIconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                selectedLabelTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w400,
                ),
                indicatorColor: Theme.of(context).colorScheme.primaryContainer,
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kIndicatorBorderRadius),
                ),

                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerLowest,

                selectedIndex:
                    _selectedRailIndex(), // highlight based on current panel
                onDestinationSelected: (i) {
                  if (i == kHomeIndex) {
                    // home: close panel
                    context.go('/dashboard/$entity');
                  } else if (i >= kCategoriesIndex && i <= kIconsIndex) {
                    context.go('/dashboard/$entity/${actions[i - 1]}');
                  } else if (i == kGraphIndex && entity == EntityType.note.id) {
                    context.go(AppRoutesPaths.notesGraph);
                  }
                },
                labelType: NavigationRailLabelType.all,
                destinations: destinations,
                leading: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: _buildExpandableFAB(entity, isMobile),
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),

              // Левая панель фильтрации (DashboardDrawerContent) для экранов >= 1000px
              if (showDrawerAsPanel && !isFullCenter)
                SizedBox(
                  width: kLeftPanelWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: DashboardDrawerContent(
                      entityType: EntityType.fromId(entity)!,
                    ),
                  ),
                ),

              // Center: если isFullCenter — panelChild, иначе DashboardHomeScreen с анимацией
              Expanded(
                child: Stack(
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
                    // Full-center content с анимацией появления,
                    // но panelChild рендерится напрямую без AnimatedSwitcher
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
                                  kFullCenterScaleBegin +
                                  (kFullCenterScaleOffset *
                                      value), // 0.92 -> 1.0
                              child: child,
                            ),
                          );
                        },
                        // panelChild рендерится как child — без пересоздания
                        child: widget.panelChild,
                      ),
                  ],
                ),
              ),

              // Анимированная правая панель — только если не isFullCenter
              if (!isMobile && !isFullCenter)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      // Вычисляем доступное пространство для центра и правой панели
                      const railWidth =
                          kRailWidth; // примерная ширина NavigationRail
                      final leftPanelWidth =
                          (showDrawerAsPanel && !isFullCenter)
                          ? kLeftPanelWidth
                          : 0.0;
                      final availableWidth =
                          constraints.maxWidth -
                          railWidth -
                          leftPanelWidth -
                          kDividerWidth; // -2 для dividers

                      return SizedBox(
                        width: availableWidth * 0.5 * _controller.value,
                        child: ClipRect(
                          child: Container(
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
                              opacity: _controller.value,
                              duration: kOpacityAnimationDuration,
                              child: hasPanel ? child : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      );
                    },
                    child: panel,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Вспомогательный метод для создания ExpandableFAB
  Widget _buildExpandableFAB(String entity, bool isMobile) {
    return ExpandableFAB(
      executeFirstActionDirectly: true,
      direction: isMobile
          ? FABExpandDirection.up
          : FABExpandDirection.rightDown,
      isUseInNavigationRail: !isMobile, // true для десктопа
      shape: isMobile ? FABShape.circle : FABShape.square,
      actions: _buildFabActions(entity, context),
    );
  }
}

// =============================================================================
// Bottom Nav Icon Button
// =============================================================================

class _BottomNavIconButton extends StatelessWidget {
  final NavigationRailDestination destination;
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
      borderRadius: BorderRadius.circular(kBottomNavBorderRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kBottomNavPaddingHorizontal,
          vertical: kBottomNavPaddingVertical,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            destination.icon,
            const SizedBox(height: kBottomNavSpacing),
            Text(
              (destination.label as Text).data ?? '',
              style: TextStyle(
                fontSize: kBottomNavFontSize,
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
