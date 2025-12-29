import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_home_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/expandable_fab.dart';

// В теле класса _DashboardLayoutState добавьте:
const List<String> _fullCenterPaths = [
  // Paths.notesGraph,
]; // сюда можно добавить другие full-center имена

/// Действия панели справа и нижнего меню
const List<String> actions = ['categories', 'tags', 'icons'];

/// DashboardLayout — stateful, хранит navigatorKeys для каждой entity и анимацию панели
class DashboardLayoutV2 extends StatefulWidget {
  final GoRouterState state;
  final Widget
  panelChild; // deepest matched route (если это panel), иначе SizedBox

  const DashboardLayoutV2({
    required this.state,
    required this.panelChild,
    super.key,
  });

  @override
  State<DashboardLayoutV2> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayoutV2>
    with SingleTickerProviderStateMixin {
  // navigatorKeys для внутреннего (центра) навигатора каждой entity
  final Map<String, GlobalKey<NavigatorState>> _navigatorKeys = {
    for (var e in EntityType.allTypesString) e: GlobalKey<NavigatorState>(),
  };

  late final AnimationController _controller;
  // ширина правой панели, когда открыта
  double _panelOpenWidth = 0.0;
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
  void didUpdateWidget(covariant DashboardLayoutV2 oldWidget) {
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

  // helper: извлечь entity из params
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
    _panelOpenWidth = screenWidth * 0.46;
    final hasPanel = _hasPanel(uri);
    final panel = hasPanel ? widget.panelChild : const SizedBox.shrink();
    final isFullCenter = _isFullCenter(uri);

    // Используем кэшированные destinations, добавляя Graph только для notes
    final destinations = entity == EntityType.note.id
        ? [..._baseDestinations, _graphDestination]
        : _baseDestinations;

    // Mobile: если есть панель — показываем её fullscreen с BottomNavigationBar
    if (isMobile && (hasPanel || isFullCenter)) {
      return Scaffold(
        body: widget.panelChild,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedRailIndex() ?? 0,
          onTap: (i) {
            if (i == 0) {
              // home: close panel
              context.go('/dashboard/$entity');
            } else if (i >= 1 && i <= 3) {
              context.go('/dashboard/$entity/${actions[i - 1]}');
            } else if (i == 4 && entity == EntityType.note.id) {
              // context.go(Paths.notesGraph);
            }
          },
          items: destinations
              .map(
                (d) => BottomNavigationBarItem(
                  icon: d.icon,
                  label: (d.label as Text).data,
                ),
              )
              .toList(),
        ),
        floatingActionButton: _shouldShowFAB(uri)
            ? _buildExpandableFAB(entity, isMobile)
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    }

    // Mobile layout без панели: BottomNavigationBar для выбора actions, как NavigationRail
    if (isMobile) {
      return Scaffold(
        // appBar: AppBar(title: const Text('Dashboard')),
        body: RepaintBoundary(
          child: IndexedStack(
            index: selectedIndex,
            children: _indexedStackChildren,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedRailIndex() ?? 0,
          onTap: (i) {
            if (i == 0) {
              // home: close panel
              context.go('/dashboard/$entity');
            } else if (i >= 1 && i <= 3) {
              context.go('/dashboard/$entity/${actions[i - 1]}');
            } else if (i == 4 && entity == EntityType.note.id) {
              // context.go(Paths.notesGraph);
            }
          },
          items: destinations
              .map(
                (d) => BottomNavigationBarItem(
                  icon: d.icon,
                  label: (d.label as Text).data,
                ),
              )
              .toList(),
        ),
        floatingActionButton: _shouldShowFAB(uri)
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
          NavigationRail(
            selectedIndex:
                _selectedRailIndex(), // highlight based on current panel
            onDestinationSelected: (i) {
              if (i == 0) {
                // home: close panel
                context.go('/dashboard/$entity');
              } else if (i >= 1 && i <= 3) {
                context.go('/dashboard/$entity/${actions[i - 1]}');
              } else if (i == 4 && entity == 'notes') {
                // context.go(Paths.notesGraph);
              }
            },
            labelType: NavigationRailLabelType.all,
            destinations: destinations,
            leading: Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: _buildExpandableFAB(entity, isMobile),
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
                  final width = _panelOpenWidth * _controller.value;
                  return SizedBox(
                    width: width,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          widthFactor: _controller.value.clamp(0.01, 1.0),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                // child вынесен из builder для оптимизации — не пересоздаётся при анимации
                child: SizedBox(
                  width: _panelOpenWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                    child: hasPanel ? panel : const SizedBox.shrink(),
                  ),
                ),
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
      actions: [
        FABActionData(
          icon: Icons.add,
          label: 'Добавить',
          onPressed: () => context.go('/dashboard/$entity/add'),
        ),
        FABActionData(
          icon: Icons.category,
          label: 'Категории',
          onPressed: () => context.go('/dashboard/$entity/categories'),
        ),
        FABActionData(
          icon: Icons.tag,
          label: 'Теги',
          onPressed: () => context.go('/dashboard/$entity/tags'),
        ),
        FABActionData(
          icon: Icons.image,
          label: 'Иконки',
          onPressed: () => context.go('/dashboard/$entity/icons'),
        ),
      ],
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
            return DashboardHomeScreen(
              entityType: EntityType.fromId(entity)!,

              // локально открываем экран деталей внутри этого Navigator (сохраняет stack)
              // openLocalDetails: (String itemId) {
              //   // key.currentState!.push(
              //   //   MaterialPageRoute(
              //   //     builder: (_) => LocalDetailPage(entity: entity, id: itemId),
              //   //   ),
              //   // );
              // },
              // для открытия панели (categories/add/edit) — используем URL навигацию
            );
          },
        );
      },
    );
  }
}

/// --- Примеры виджетов ---
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
