import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/expandable_fab.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:universal_platform/universal_platform.dart';

// ===========================================================================
// Constants
// ===========================================================================

// Animation durations
const Duration kPanelAnimationDuration = Duration(milliseconds: 280);
const Duration kFadeAnimationDuration = Duration(milliseconds: 250);
const Duration kScaleAnimationDuration = Duration(milliseconds: 300);
const Duration kOpacityAnimationDuration = Duration(milliseconds: 150);

// Screen breakpoints

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

// Floating bottom navigation
const double kFloatingNavMarginHorizontal = 12.0;
const double kFloatingNavMarginBottom = 24.0;
const double kFloatingNavBarBorderRadius = 28.0;
const double kFloatingNavBarHeight = 64.0;
const double kFloatingNavShadowBlurRadius = 20.0;
const double kFloatingNavShadowOpacity = 0.12;
const double kFloatingNavShadowOffsetY = 4.0;
const double kFloatingNavItemBorderRadius = 16.0;
const double kFloatingNavItemPaddingH = 8.0;
const double kFloatingNavItemPaddingV = 6.0;
const double kFloatingNavIconSize = 22.0;
const double kFloatingNavLabelFontSize = 10.0;
const double kFloatingNavLabelSpacing = 2.0;
const double kFloatingNavFabBottomOffset = 12.0;

// Segment indicator
const Duration kSegmentIndicatorDuration = Duration(milliseconds: 300);
const double kSegmentIndicatorVerticalPadding = 6.0;
const double kSegmentIndicatorHorizontalPadding = 6.0;

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
  List<FABActionData> _buildFabActions(
    String entity,
    BuildContext context,
    String? currentAction,
  ) {
    final theme = Theme.of(context);

    // Если на странице categories/tags/icons, первым действием — добавить соответствующий элемент
    FABActionData? primaryAction;
    if (currentAction == 'categories') {
      primaryAction = FABActionData(
        icon: Icons.add,
        label: 'Добавить категорию',
        onPressed: () => _onFabActionPressed(entity, 'add_category'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      );
    } else if (currentAction == 'tags') {
      primaryAction = FABActionData(
        icon: Icons.add,
        label: 'Добавить тег',
        onPressed: () => _onFabActionPressed(entity, 'add_tag'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      );
    } else if (currentAction == 'icons') {
      primaryAction = FABActionData(
        icon: Icons.add,
        label: 'Добавить иконку',
        onPressed: () => _onFabActionPressed(entity, 'add_icon'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      );
    }

    final actions = <FABActionData>[];
    if (primaryAction != null) {
      actions.add(primaryAction);
    } else {
      // Стандартные действия для главной страницы entity
      actions.add(
        FABActionData(
          icon: Icons.add,
          label: 'Добавить',
          onPressed: () => _onFabActionPressed(entity, 'add'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      );
    }

    // Остальные действия
    actions.addAll([
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
    ]);

    return actions;
  }

  /// Обработать нажатие на FAB action
  void _onFabActionPressed(String entity, String action) {
    final entityType = EntityType.fromId(entity)!;
    String path;

    switch (action) {
      case 'add':
        path = '/dashboard/$entity/add';
        break;
      case 'add_category':
        path = AppRoutesPaths.categoryAdd(entityType);
        break;
      case 'add_tag':
        path = AppRoutesPaths.tagsAdd(entityType);
        break;
      case 'add_icon':
        path = AppRoutesPaths.iconAddForEntity(entityType);
        break;
      case 'categories':
        path = '/dashboard/$entity/categories';
        break;
      case 'tags':
        path = '/dashboard/$entity/tags';
        break;
      case 'icons':
        path = '/dashboard/$entity/icons';
        break;
      default:
        path = '/dashboard/$entity/$action';
    }

    if (context.mounted) {
      context.go(path);
    }
  }

  // ===========================================================================
  // Floating Bottom Navigation Bar
  // ===========================================================================

  /// Построить плавающий BottomNavigationBar для мобильных устройств
  Widget _buildFloatingBottomNav(
    String entity,
    List<NavigationRailDestination> destinations,
  ) {
    final currentIndex = _selectedRailIndex() ?? 0;
    final systemPadding = MediaQuery.of(context).viewPadding;

    return Positioned(
      bottom: UniversalPlatform.isDesktop
          ? kBottomNavNotchMargin
          : systemPadding.bottom,
      left: kFloatingNavMarginHorizontal,
      right: kFloatingNavMarginHorizontal,
      child: _FloatingNavBar(
        destinations: destinations,
        selectedIndex: currentIndex,
        onItemSelected: (index) => _onBottomNavItemSelected(entity, index),
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

  // Проверяем, нужно ли показывать FAB (на 2-сегментных путях и на categories/tags/icons)
  bool _shouldShowFAB(String location) {
    final segments = Uri.parse(location).pathSegments;
    if (segments.length == kPathSegmentsForEntity) {
      return true; // /dashboard/entity
    }
    if (segments.length == kMinPathSegmentsForPanel &&
        actions.contains(segments[2])) {
      return true; // /dashboard/:entity/categories, /dashboard/:entity/tags, /dashboard/:entity/icons
    }
    return false;
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

  bool _isMobileLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width < MainConstants.kMobileBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    final uri = widget.state.uri.toString();
    final entity = _currentEntity();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final systemPadding = MediaQuery.of(context).viewPadding;
    final isMobile = _isMobileLayout(context);
    final showDrawerAsPanel =
        screenWidth >=
        MainConstants
            .kDesktopBreakpoint; // Показывать drawer как панель для больших экранов
    final hasPanel = _hasPanel(uri);
    final panel = widget.panelChild;
    final isFullCenter = _isFullCenter(uri);

    // Используем кэшированные destinations, добавляя Graph только для notes
    final destinations = entity == EntityType.note.id
        ? [..._baseDestinations, _graphDestination]
        : _baseDestinations;

    // Mobile: единый layout с Stack и floating bottom navigation
    if (isMobile) {
      final showPanel = hasPanel || isFullCenter;
      final showBottomNav = _shouldShowBottomNav(uri) && !isFullCenter;
      final showFAB = _shouldShowFAB(uri);

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
                  child: Container(key: const ValueKey('panel'), child: panel),
                ),
              ),
            ),

            // Floating bottom navigation bar
            if (showBottomNav) _buildFloatingBottomNav(entity, destinations),

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
                child: AnimatedScale(
                  scale: showFAB ? 1.0 : 0.0,
                  duration: kScaleAnimationDuration,
                  curve: showFAB ? Curves.easeOutBack : Curves.easeIn,
                  child: AnimatedOpacity(
                    opacity: showFAB ? 1.0 : 0.0,
                    duration: kFadeAnimationDuration,
                    curve: Curves.easeInOut,
                    child: IgnorePointer(
                      ignoring: !showFAB,
                      child: _buildExpandableFAB(entity, isMobile),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
              // Анимируется в противофазе с правой панелью
              if (showDrawerAsPanel && !isFullCenter)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      // Левая панель сворачивается когда правая открывается
                      // При _controller.value = 0 (панель закрыта) -> width = kLeftPanelWidth
                      // При _controller.value = 1 (панель открыта) -> width = 0
                      final leftPanelWidthAnimated =
                          kLeftPanelWidth * (1.0 - _controller.value);
                      return SizedBox(
                        width: leftPanelWidthAnimated,
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.centerLeft,
                            minWidth: kLeftPanelWidth,
                            maxWidth: kLeftPanelWidth,
                            child: AnimatedOpacity(
                              opacity: 1.0 - _controller.value,
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
                      child: DashboardDrawerContent(
                        entityType: EntityType.fromId(entity)!,
                      ),
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
                      // Левая панель анимируется в противофазе
                      final leftPanelWidth =
                          (showDrawerAsPanel && !isFullCenter)
                          ? kLeftPanelWidth * (1.0 - _controller.value)
                          : 0.0;
                      final availableWidth =
                          constraints.maxWidth -
                          railWidth -
                          leftPanelWidth -
                          kDividerWidth; // -2 для dividers

                      final rightPanelMaxWidth = availableWidth * 0.5;
                      final rightPanelWidthAnimated =
                          rightPanelMaxWidth * _controller.value;

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
                                opacity: _controller.value,
                                duration: kOpacityAnimationDuration,
                                child: child,
                              ),
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
    final uri = widget.state.uri.toString();
    final segments = Uri.parse(uri).pathSegments;
    final currentAction =
        isMobile && segments.length >= kMinPathSegmentsForPanel
        ? segments[2]
        : null;

    return ExpandableFAB(
      executeFirstActionDirectly: true,
      direction: isMobile
          ? FABExpandDirection.up
          : FABExpandDirection.rightDown,
      isUseInNavigationRail: !isMobile, // true для десктопа
      shape: isMobile ? FABShape.circle : FABShape.square,
      actions: _buildFabActions(entity, context, currentAction),
    );
  }
}

// =============================================================================
// Floating Nav Bar with Segment Control Animation
// =============================================================================

/// Плавающий навигационный бар со скользящим индикатором
/// в стиле segment control.
class _FloatingNavBar extends StatelessWidget {
  final List<NavigationRailDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const _FloatingNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemCount = destinations.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(kFloatingNavBarBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).shadowColor.withValues(alpha: kFloatingNavShadowOpacity),
            blurRadius: kFloatingNavShadowBlurRadius,
            offset: const Offset(0, kFloatingNavShadowOffsetY),
          ),
        ],
      ),
      child: SizedBox(
        height: kFloatingNavBarHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final itemWidth = totalWidth / itemCount;
            final indicatorLeft =
                selectedIndex * itemWidth + kSegmentIndicatorHorizontalPadding;
            final indicatorWidth =
                itemWidth - kSegmentIndicatorHorizontalPadding * 2;

            return Stack(
              children: [
                // Скользящий индикатор
                AnimatedPositioned(
                  duration: kSegmentIndicatorDuration,
                  curve: Curves.easeOutCubic,
                  left: indicatorLeft,
                  top: kSegmentIndicatorVerticalPadding,
                  bottom: kSegmentIndicatorVerticalPadding,
                  width: indicatorWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                // Элементы навигации
                Row(
                  children: destinations
                      .asMap()
                      .entries
                      .map(
                        (entry) => Expanded(
                          child: _FloatingNavItem(
                            destination: entry.value,
                            isSelected: selectedIndex == entry.key,
                            onTap: () => onItemSelected(entry.key),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// Floating Nav Item
// =============================================================================

class _FloatingNavItem extends StatelessWidget {
  final NavigationRailDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _FloatingNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
    );
  }
}
