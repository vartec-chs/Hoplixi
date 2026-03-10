import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/dashboard_drawer.dart';
import 'package:universal_platform/universal_platform.dart';

import 'dashboard_drawer_scope.dart';
import 'dashboard_layout_constants.dart';
import 'widgets/fab_builder.dart';
import 'widgets/floating_nav_bar.dart';

/// Mobile-специфичный layout для DashboardLayout.
///
/// Отображает контент из роутинга ([child]) с floating bottom navigation
/// и FAB. DashboardHomeScreen приходит из роутера как [child] на базовом
/// маршруте, панели (categories, tags, etc.) — на sub-маршрутах.
///
/// При смене маршрута контент плавно появляется через fade-in анимацию.
/// Используется fade-in-only (без crossfade), чтобы избежать конфликтов
/// GlobalKey — в дереве всегда только один экземпляр child.
///
/// **Архитектура:** Navigator content размещён ВНЕ Scaffold.body, чтобы
/// избежать вложенных `_RenderLayoutBuilder` (Scaffold._BodyBuilder).
/// Дочерние экраны (form/view) имеют свои Scaffold, и если они находятся
/// внутри внешнего Scaffold.body, при смене маршрута внутренний
/// `_RenderLayoutBuilder` мутируется во время `performLayout` внешнего,
/// что вызывает assertion error. Scaffold используется только для drawer.
class MobileDashboardLayout extends StatefulWidget {
  /// Текущий entity (passwords, notes, etc.)
  final String entity;

  /// Текущий URI
  final String uri;

  /// Контент из роутера (DashboardHomeScreen или панель)
  final Widget child;

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
    required this.child,
    required this.showBottomNav,
    required this.showFAB,
    required this.currentAction,
    required this.destinations,
    required this.onNavItemSelected,
    required this.selectedIndex,
    super.key,
  });

  @override
  State<MobileDashboardLayout> createState() => _MobileDashboardLayoutState();
}

class _MobileDashboardLayoutState extends State<MobileDashboardLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Флаг открытости drawer — управляет IgnorePointer на Scaffold-обёртке.
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: kFadeAnimationDuration,
      value: 1.0, // начинаем с полной видимости
    );
  }

  @override
  void didUpdateWidget(covariant MobileDashboardLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      // Сброс opacity и запуск fade-in при смене маршрута.
      _fadeController.value = 0.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fadeController.forward();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final systemPadding = MediaQuery.of(context).viewPadding;

    // DashboardDrawerScope предоставляет openDrawer() потомкам
    // (в частности DashboardHomeScreen), т.к. Navigator content
    // находится вне Scaffold и Scaffold.of(context) недоступен.
    return DashboardDrawerScope(
      openDrawer: _openDrawer,
      child: Stack(
        children: [
          // 1. Navigator content — вне Scaffold.body, чтобы избежать
          //    вложенных _RenderLayoutBuilder (Scaffold._BodyBuilder).
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeController,
              child: widget.child,
            ),
          ),

          // 2. Scaffold ТОЛЬКО для drawer. Body пустой (SizedBox.expand),
          //    поэтому его _BodyBuilder._RenderLayoutBuilder не конфликтует
          //    с _RenderLayoutBuilder дочерних Scaffold-ов в Navigator.
          //    IgnorePointer когда drawer закрыт — touches проходят к content.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isDrawerOpen,
              child: Scaffold(
                key: _scaffoldKey,
                backgroundColor: Colors.transparent,
                onDrawerChanged: (isOpen) {
                  setState(() => _isDrawerOpen = isOpen);
                },
                drawer: DashboardDrawer(
                  entityType:
                      EntityType.fromId(widget.entity) ?? EntityType.password,
                ),
                body: const SizedBox.expand(),
              ),
            ),
          ),

          // 3. Floating bottom navigation bar
          Positioned(
            bottom: UniversalPlatform.isDesktop
                ? kBottomNavNotchMargin
                : systemPadding.bottom,
            left: kFloatingNavMarginHorizontal,
            right: kFloatingNavMarginHorizontal,
            child: IgnorePointer(
              ignoring: !widget.showBottomNav,
              child: AnimatedSlide(
                offset: widget.showBottomNav
                    ? Offset.zero
                    : const Offset(0, 1.5),
                duration: kScaleAnimationDuration,
                curve: widget.showBottomNav
                    ? Curves.easeOutCubic
                    : Curves.easeInCubic,
                child: AnimatedOpacity(
                  opacity: widget.showBottomNav ? 1.0 : 0.0,
                  duration: kFadeAnimationDuration,
                  curve: Curves.easeInOut,
                  child: AnimatedScale(
                    scale: widget.showBottomNav ? 1.0 : 0.95,
                    duration: kScaleAnimationDuration,
                    curve: widget.showBottomNav
                        ? Curves.easeOutBack
                        : Curves.easeIn,
                    child: FloatingNavBar(
                      destinations: widget.destinations,
                      selectedIndex: widget.selectedIndex,
                      onItemSelected: widget.onNavItemSelected,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. FAB выше floating nav
          Positioned(
            bottom: widget.showBottomNav && UniversalPlatform.isDesktop
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
                opacity: widget.showFAB ? 1.0 : 0.0,
                duration: kOpacityAnimationDuration,
                curve: widget.showFAB ? Curves.easeOutBack : Curves.easeIn,
                child: AnimatedSlide(
                  offset: widget.showBottomNav
                      ? Offset.zero
                      : const Offset(0, 1.5),
                  duration: kFadeAnimationDuration,
                  curve: Curves.easeInOut,
                  child: IgnorePointer(
                    ignoring: !widget.showFAB,
                    child: DashboardFabBuilder(
                      context: context,
                      entity: widget.entity,
                      currentAction: widget.currentAction,
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
