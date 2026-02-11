import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer.dart';

import 'dashboard_layout_constants.dart';
import 'keyboard_shortcuts.dart';
import 'widgets/fab_builder.dart';

/// Desktop-специфичный layout для DashboardLayout.
///
/// Side-by-side режим: [DashboardHomeScreen] всегда отображается как
/// основной контент, а [panelChild] показывается как анимированная
/// правая панель при навигации на sub-маршруты (categories, tags, icons).
///
/// В full-center режиме (graph) — только [panelChild] занимает всё
/// пространство.
class DesktopDashboardLayout extends StatefulWidget {
  /// Текущий entity (passwords, notes, etc.)
  final String entity;

  /// Текущий URI
  final String uri;

  /// Контент из роутера (панель: CategoryManager, TagsManager и т.д.)
  final Widget child;

  /// Есть ли активная правая панель (sub-маршрут)
  final bool hasPanel;

  /// Находится ли в режиме full-center (graph)
  final bool isFullCenter;

  /// Destinations для навигации
  final List<NavigationRailDestination> destinations;

  /// Текущий индекс навигации
  final int? selectedIndex;

  /// Callback при выборе пункта навигации
  final ValueChanged<int> onNavItemSelected;

  const DesktopDashboardLayout({
    required this.entity,
    required this.uri,
    required this.child,
    required this.hasPanel,
    required this.isFullCenter,
    required this.destinations,
    required this.selectedIndex,
    required this.onNavItemSelected,
    super.key,
  });

  @override
  State<DesktopDashboardLayout> createState() => _DesktopDashboardLayoutState();
}

class _DesktopDashboardLayoutState extends State<DesktopDashboardLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _panelAnimation;

  /// Покривлённая анимация для плавного перехода панелей.
  ///
  /// Линейная анимация вызывает «дерганье» при одновременном
  /// изменении ширины трёх секций (левая, центр, правая).
  /// `easeInOutCubic` сглаживает начало и конец.
  late final CurvedAnimation _curvedAnimation;

  /// Флаг: строить ли контент правой панели в дереве виджетов.
  bool _showChild = false;

  /// Кэшированный виджет правой панели.
  ///
  /// При обратной навигации (sub-маршрут → базовый) роутер мгновенно
  /// заменяет [widget.child] на `DashboardHomeScreen`. Если использовать
  /// [widget.child] напрямую во время reverse-анимации, возникнут два
  /// экземпляра `DashboardHomeScreen`. Поэтому сохраняем предыдущий
  /// контент панели и показываем его пока анимация закрытия не завершится.
  Widget? _lastPanelChild;

  @override
  void initState() {
    super.initState();
    _showChild = widget.hasPanel;
    if (widget.hasPanel) {
      _lastPanelChild = widget.child;
    }
    _panelAnimation = AnimationController(
      vsync: this,
      duration: kPanelAnimationDuration,
      value: widget.hasPanel ? 1.0 : 0.0,
    );
    _curvedAnimation = CurvedAnimation(
      parent: _panelAnimation,
      curve: Curves.easeInOutCubic,
    );
    _panelAnimation.addStatusListener(_onAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant DesktopDashboardLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasPanel != oldWidget.hasPanel) {
      if (widget.hasPanel) {
        _lastPanelChild = widget.child;
        setState(() => _showChild = true);
        _panelAnimation.forward();
      } else {
        // _lastPanelChild сохраняет предыдущий контент для
        // reverse-анимации, _showChild остаётся true
        _panelAnimation.reverse();
      }
    } else if (widget.hasPanel) {
      // Контент панели обновился (например categories → tags)
      _lastPanelChild = widget.child;
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _showChild) {
      setState(() {
        _showChild = false;
        _lastPanelChild = null;
      });
    }
  }

  @override
  void dispose() {
    _panelAnimation.removeStatusListener(_onAnimationStatus);
    _curvedAnimation.dispose();
    _panelAnimation.dispose();
    super.dispose();
  }

  // =========================================================================
  // Helpers
  // =========================================================================

  /// Определяет, достаточно ли ширины для одновременного показа
  /// левой и правой панелей рядом с основным контентом.
  ///
  /// Если ширины не хватает, левая панель плавно скрывается при
  /// открытии правой (и наоборот).
  bool _canShowBothPanels(double screenWidth) {
    return screenWidth >= kBothPanelsBreakpoint;
  }

  // =========================================================================
  // Keyboard Shortcuts
  // =========================================================================

  void _handleGoBack() {
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      // Возврат на главную dashboard текущей сущности
      context.go('/dashboard/${widget.entity}');
    }
  }

  void _handleCreateEntity() {
    if (!context.mounted) return;
    context.go('/dashboard/${widget.entity}/add');
  }

  void _handleOpenTags() {
    if (!context.mounted) return;
    context.go('/dashboard/${widget.entity}/tags');
  }

  void _handleOpenCategories() {
    if (!context.mounted) return;
    context.go('/dashboard/${widget.entity}/categories');
  }

  void _handleOpenIcons() {
    if (!context.mounted) return;
    context.go('/dashboard/${widget.entity}/icons');
  }

  // =========================================================================
  // Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showDrawerAsPanel = screenWidth >= MainConstants.kDesktopBreakpoint;
    final canShowBoth = _canShowBothPanels(screenWidth);

    // Пространство, доступное для центра + правой панели.
    // Rail (80) + divider (1) всегда вычитаются.
    // Если левая панель статична (canShowBoth) — вычитаем и её.
    final fixedWidth = kRailWidth + 1 + (canShowBoth ? kLeftPanelWidth + 1 : 0);
    final contentWidth = screenWidth - fixedWidth;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        kShortcutGoBack: _handleGoBack,
        kShortcutCreateEntity: _handleCreateEntity,
        kShortcutOpenTags: _handleOpenTags,
        kShortcutOpenCategories: _handleOpenCategories,
        kShortcutOpenIcons: _handleOpenIcons,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              _buildNavigationRail(context),
              const VerticalDivider(width: 1, thickness: 1),

              // Full-center режим (graph и т.д.) — только child
              if (widget.isFullCenter)
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey(widget.uri),
                    child: widget.child,
                  ),
                )
              else ...[
                // Левая панель фильтрации (>= desktop breakpoint)
                if (showDrawerAsPanel)
                  _buildLeftPanel(context, canShowBoth: canShowBoth),

                // DashboardHomeScreen — всегда видим
                Expanded(
                  child: DashboardHomeScreen(
                    key: ValueKey('desktop_home_${widget.entity}'),
                    entityType: EntityType.fromId(widget.entity)!,
                  ),
                ),

                // Анимированная правая панель
                _buildRightPanel(context, contentWidth),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // Navigation Rail
  // =========================================================================

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
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: widget.onNavItemSelected,
      labelType: NavigationRailLabelType.all,
      destinations: widget.destinations,
      leading: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: DashboardFabBuilder(
          context: context,
          entity: widget.entity,
          currentAction: null,
          isMobile: false,
        ).buildExpandableFAB(),
      ),
    );
  }

  // =========================================================================
  // Left Panel (Drawer as Panel) — анимированная
  // =========================================================================

  Widget _buildLeftPanel(BuildContext context, {required bool canShowBoth}) {
    // Если экран достаточно широкий для обеих панелей —
    // левая панель всегда видна (статичная)
    if (canShowBoth) {
      return Container(
        width: kLeftPanelWidth,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        child: DashboardDrawerContent(
          entityType: EntityType.fromId(widget.entity)!,
        ),
      );
    }

    // Экран не достаточно широкий — левая панель скрывается
    // при открытии правой (обратная анимация от _panelAnimation)
    return AnimatedBuilder(
      animation: _curvedAnimation,
      builder: (context, child) {
        // 1.0 → правая панель полностью открыта → левая скрыта
        // 0.0 → правая панель закрыта → левая видна
        final progress = 1.0 - _curvedAnimation.value;
        final width = progress * kLeftPanelWidth;
        if (width < 1) return const SizedBox.shrink();

        return SizedBox(
          width: width,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerRight,
              maxWidth: kLeftPanelWidth,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: kLeftPanelWidth,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        child: DashboardDrawerContent(
          entityType: EntityType.fromId(widget.entity)!,
        ),
      ),
    );
  }

  // =========================================================================
  // Right Panel (Animated)
  // =========================================================================

  /// Правая панель занимает половину [contentWidth], чтобы
  /// центральный контент и правая панель были ≈ одинаковой ширины.
  Widget _buildRightPanel(BuildContext context, double contentWidth) {
    final panelMaxWidth = contentWidth / 2;

    return AnimatedBuilder(
      animation: _curvedAnimation,
      builder: (context, child) {
        final width = _curvedAnimation.value * panelMaxWidth;
        if (width < 1) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VerticalDivider(width: 1, thickness: 1),
            SizedBox(
              width: width - 1,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  maxWidth: panelMaxWidth - 1,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
      // Используется _lastPanelChild (а не widget.child), чтобы
      // во время reverse-анимации показывать предыдущий контент
      // панели, а не DashboardHomeScreen из роутера
      child: _showChild && _lastPanelChild != null
          ? KeyedSubtree(key: ValueKey(widget.uri), child: _lastPanelChild!)
          : null,
    );
  }
}
