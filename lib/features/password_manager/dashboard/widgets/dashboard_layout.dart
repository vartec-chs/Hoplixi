import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/expandable_fab.dart';
import 'package:hoplixi/routing/paths.dart';

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
  // navigatorKeys для внутреннего (центра) навигатора каждой entity
  final Map<String, GlobalKey<NavigatorState>> _navigatorKeys = {
    for (var e in EntityType.allTypesString) e: GlobalKey<NavigatorState>(),
  };

  late final AnimationController _controller;
  bool _wasPanelOpen = false;

  // Кэшированные destinations для NavigationRail
  static const List<NavigationRailDestination> _baseDestinations = [
    NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
    NavigationRailDestination(
      icon: Icon(Icons.category),
      label: Text('Categories'),
    ),
    NavigationRailDestination(icon: Icon(Icons.tag), label: Text('Tags')),
    NavigationRailDestination(icon: Icon(Icons.image), label: Text('Icons')),
  ];

  static const NavigationRailDestination _graphDestination =
      NavigationRailDestination(
        icon: Icon(Icons.bubble_chart),
        label: Text('Graph'),
      );

  // Кэшированный список children для IndexedStack
  late final List<Widget> _indexedStackChildren;

  // Кешированные Navigator виджеты для избежания пересоздания
  late final Map<String, Widget> _cachedNavigators;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    // Кешируем Navigator виджеты один раз
    _cachedNavigators = {
      for (var e in EntityType.allTypesString) e: _buildInnerNavigator(e),
    };

    // Кэшируем список children для IndexedStack
    _indexedStackChildren = EntityType.allTypesString
        .map((e) => _cachedNavigators[e]!)
        .toList();

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
  List<FABActionData> _buildFabActions(String entity) {
    return [
      FABActionData(
        icon: Icons.add,
        label: 'Добавить',
        onPressed: () => _onFabActionPressed(entity, 'add'),
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
    final homeIndex = 0;

    final leftDestinations = destinations
        .where((d) => d == destinations[0] || d == destinations[1])
        .toList();
    final rightDestinations = destinations
        .where((d) => destinations.indexOf(d) > 1)
        .toList();

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
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
              isSelected: currentIndex == destinations.indexOf(d),
              onTap: () =>
                  _onBottomNavItemSelected(entity, destinations.indexOf(d)),
            ),
          ),
          // FAB space
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: currentIndex == homeIndex ? 40 : 0,
            child: const SizedBox(width: 40),
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
    if (index == 0) {
      // home: close panel
      context.go('/dashboard/$entity');
    } else if (index >= 1 && index <= 3) {
      context.go('/dashboard/$entity/${actions[index - 1]}');
    } else if (index == 4 && entity == EntityType.note.id) {
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
    return segments.length >= 3;
  }

  bool _isFullCenter(String location) {
    return _fullCenterPaths.contains(location);
  }

  int _indexForEntity(String entity) =>
      EntityType.allTypesString.indexOf(entity);

  // Проверяем, нужно ли показывать FAB (только на 2-сегментных путях)
  bool _shouldShowFAB(String location) {
    final segments = Uri.parse(location).pathSegments;
    return segments.length == 2; // /dashboard/entity
  }

  // Проверяем, нужно ли показывать BottomNavigationBar на мобильных устройствах
  bool _shouldShowBottomNav(String location) {
    final segments = Uri.parse(location).pathSegments;
    if (segments.length < 2) return false;
    if (segments.length == 2) return true; // /dashboard/:entity
    if (segments.length == 3 && actions.contains(segments[2]))
      return true; // /dashboard/:entity/action
    return false;
  }

  int? _selectedRailIndex() {
    final location = widget.state.uri.toString();
    final segments = Uri.parse(location).pathSegments;
    if (segments.length < 3) return 0; // home
    final action = segments[2];
    switch (action) {
      case 'categories':
        return 1;
      case 'tags':
        return 2;
      case 'icons':
        return 3;
      case 'graph':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = widget.state.uri.toString();
    final entity = _currentEntity();
    final selectedIndex = _indexForEntity(entity);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;
    final panelOpenWidth = screenWidth * 0.46;
    final hasPanel = _hasPanel(uri);
    final panel = hasPanel ? widget.panelChild : const SizedBox.shrink();
    final isFullCenter = _isFullCenter(uri);

    // Используем кэшированные destinations, добавляя Graph только для notes
    final destinations = entity == EntityType.note.id
        ? [..._baseDestinations, _graphDestination]
        : _baseDestinations;

    // Mobile: единый layout с Stack для избежания мигания
    if (isMobile) {
      return Scaffold(
        body: Stack(
          children: [
            // Центр: IndexedStack с inner Navigators
            RepaintBoundary(
              child: IndexedStack(
                index: selectedIndex,
                children: _indexedStackChildren,
              ),
            ),
            // Анимированная панель поверх центра
            AnimatedOpacity(
              opacity: (hasPanel || isFullCenter) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: (hasPanel || isFullCenter)
                  ? widget.panelChild
                  : const SizedBox.shrink(),
            ),
            // Анимированная bottom navigation bar
            // Positioned(
            //   bottom: 0,
            //   left: 0,
            //   right: 0,
            //   child: AnimatedSlide(
            //     offset: (hasPanel || isFullCenter)
            //         ? const Offset(0, 1)
            //         : Offset.zero,
            //     duration: const Duration(milliseconds: 300),
            //     curve: Curves.easeInOut,
            //     child: _buildBottomNavigationBar(entity, destinations),
            //   ),
            // ),
          ],
        ),
        bottomNavigationBar: (_shouldShowBottomNav(uri) && !isFullCenter)
            ? _buildBottomNavigationBar(entity, destinations)
            : null,
        floatingActionButton:
            (_shouldShowFAB(uri) && !(hasPanel || isFullCenter))
            ? _buildExpandableFAB(entity, isMobile)
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    }

    // Desktop/tablet: трёхколоночный layout с animated panel
    return Scaffold(
      // appBar: AppBar(title: Text('${GoRouter.of(context).state.uri}')),
      body: Row(
        children: [
          // NavigationRail / left menu для categories, tags, icons
          Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: NavigationRail(
              selectedIndex:
                  _selectedRailIndex(), // highlight based on current panel
              onDestinationSelected: (i) {
                if (i == 0) {
                  // home: close panel
                  context.go('/dashboard/$entity');
                } else if (i >= 1 && i <= 3) {
                  context.go('/dashboard/$entity/${actions[i - 1]}');
                } else if (i == 4 && entity == 'notes') {
                  context.go(AppRoutesPaths.notesGraph);
                }
              },
              labelType: NavigationRailLabelType.all,
              destinations: destinations,
              leading: Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                child: _buildExpandableFAB(entity, isMobile),
              ),
            ),
          ),

          // Center: если isFullCenter — panelChild, иначе IndexedStack с inner Navigators
          Expanded(
            flex: 3,
            child: RepaintBoundary(
              child: isFullCenter
                  ? widget.panelChild
                  : IndexedStack(
                      index: selectedIndex,
                      children: _indexedStackChildren,
                    ),
            ),
          ),

          // Анимированная правая панель — только если не isFullCenter
          if (!isMobile && !isFullCenter)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final widthFactor = isFullCenter ? 0.0 : _controller.value;

                  return ClipRect(
                    child: Align(
                      alignment: Alignment.centerRight,
                      widthFactor: widthFactor,
                      child: SizedBox(
                        width: panelOpenWidth,
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
                            opacity: widthFactor,
                            duration: const Duration(milliseconds: 150),
                            child: hasPanel ? child : const SizedBox.shrink(),
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
      ),
    );
  }

  // Вспомогательный метод для создания ExpandableFAB
  Widget _buildExpandableFAB(String entity, bool isMobile) {
    return ExpandableFAB(
      direction: isMobile
          ? FABExpandDirection.up
          : FABExpandDirection.rightDown,
      isUseInNavigationRail: !isMobile, // true для десктопа
      shape: isMobile ? FABShape.circle : FABShape.square,
      actions: _buildFabActions(entity),
    );
  }

  // inner Navigator для сущности — сохраняет стек и scroll
  Widget _buildInnerNavigator(String entity) {
    final key = _navigatorKeys[entity]!;
    return Navigator(
      key: key,
      onGenerateRoute: (settings) {
        // Роуты внутренние — здесь можно расширять локальные пути (например item/details),
        // но в примере достаточно одного корневого экрана.
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            return DashboardHomeScreen(entityType: EntityType.fromId(entity)!);
          },
        );
      },
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            destination.icon,
            const SizedBox(height: 4),
            Text(
              (destination.label as Text).data ?? '',
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

/// Центр для entity (локальные навигации через openLocalDetails, панель — через openPanel)
// class EntityCenterPage extends StatelessWidget {
//   final String entity;
//   final void Function(String itemId) openLocalDetails;
//   final void Function(String pathSuffix) openPanel;

//   const EntityCenterPage({
//     required this.entity,
//     required this.openLocalDetails,
//     required this.openPanel,
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // простой плейсхолдер списка
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             DropdownButton<String>(
//               value: entity,
//               onChanged: (newEntity) {
//                 if (newEntity != null) {
//                   context.go('/dashboard/$newEntity');
//                 }
//               },
//               items: EntityType.allTypesString
//                   .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                   .toList(),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 key: PageStorageKey(
//                   'list_$entity',
//                 ), // хранит позицию скролла в IndexedStack
//                 itemCount: 30,
//                 itemBuilder: (context, i) {
//                   final id = 'item_$i';
//                   return ListTile(
//                     title: Text('$entity — item $i'),
//                     onTap: () => openLocalDetails(id), // локальная навигация
//                     trailing: PopupMenuButton<String>(
//                       onSelected: (v) {
//                         if (v == 'edit') openPanel('edit/$id');
//                         if (v == 'history') openPanel('history/$id');
//                       },
//                       itemBuilder: (ctx) => [
//                         const PopupMenuItem(value: 'edit', child: Text('Edit')),
//                         const PopupMenuItem(
//                           value: 'history',
//                           child: Text('History'),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
