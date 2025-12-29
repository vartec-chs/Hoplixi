// import 'package:flutter/material.dart';
// import 'package:hoplixi/routing/paths.dart';

// /// Callback для проверки видимости элемента навигации
// typedef DestinationVisibilityCallback = bool Function(BuildContext context);

// /// Определение элементов навигации Dashboard.
// ///
// /// Каждый элемент содержит всю необходимую информацию для отображения
// /// в NavigationRail (desktop) и BottomNavigationBar (mobile).
// ///
// /// Для добавления нового пункта меню:
// /// 1. Добавить новое значение в enum
// /// 2. Добавить соответствующий путь в [AppRoutesPaths]
// /// 3. При необходимости добавить matchPatterns для вложенных путей
// enum DashboardDestination {
//   /// Главная страница dashboard
//   home(
//     path: AppRoutesPaths.dashboardHome,
//     matchPatterns: ['/dashboard/home'],
//     label: 'Главная',
//     icon: Icons.dashboard_outlined,
//     selectedIcon: Icons.dashboard,
//     opensSidebar: false,
//   ),

//   /// Управление категориями
//   categories(
//     path: AppRoutesPaths.dashboardCategoryManager,
//     matchPatterns: [
//       '/dashboard/category-manager',
//       '/dashboard/category-manager/',
//     ],
//     label: 'Категории',
//     icon: Icons.folder_outlined,
//     selectedIcon: Icons.folder,
//     opensSidebar: true,
//   ),

//   /// Управление иконками
//   icons(
//     path: AppRoutesPaths.dashboardIconManager,
//     matchPatterns: ['/dashboard/icon-manager', '/dashboard/icon-manager/'],
//     label: 'Иконки',
//     icon: Icons.import_contacts_outlined,
//     selectedIcon: Icons.import_contacts,
//     opensSidebar: true,
//   ),

//   /// Управление тегами
//   tags(
//     path: AppRoutesPaths.dashboardTagManager,
//     matchPatterns: ['/dashboard/tag-manager', '/dashboard/tag-manager/'],
//     label: 'Теги',
//     icon: Icons.tag_outlined,
//     selectedIcon: Icons.tag,
//     opensSidebar: true,
//   );

//   const DashboardDestination({
//     required this.path,
//     required this.matchPatterns,
//     required this.label,
//     required this.icon,
//     required this.selectedIcon,
//     required this.opensSidebar,
//   });

//   /// Основной путь для навигации
//   final String path;

//   /// Паттерны путей для сопоставления (включая вложенные)
//   /// Используется в [fromPath] для определения активного destination
//   final List<String> matchPatterns;

//   /// Отображаемое название
//   final String label;

//   /// Иконка в невыбранном состоянии
//   final IconData icon;

//   /// Иконка в выбранном состоянии
//   final IconData selectedIcon;

//   /// Открывает ли sidebar при выборе
//   final bool opensSidebar;

//   // ===========================================================================
//   // Factory Methods
//   // ===========================================================================

//   /// Получить destination по индексу (используется встроенный enum.index)
//   ///
//   /// Возвращает [home] если индекс не найден
//   static DashboardDestination fromIndex(int idx) {
//     if (idx >= 0 && idx < DashboardDestination.values.length) {
//       return DashboardDestination.values[idx];
//     }
//     return DashboardDestination.home;
//   }

//   /// Получить destination по текущему пути
//   ///
//   /// Проверяет [matchPatterns] каждого destination для определения
//   /// активного элемента. Поддерживает вложенные пути.
//   ///
//   /// Возвращает [home] если путь не соответствует ни одному destination
//   static DashboardDestination fromPath(String location) {
//     // Сначала проверяем точное совпадение с основным путём
//     for (final destination in DashboardDestination.values) {
//       if (location == destination.path) {
//         return destination;
//       }
//     }

//     // Затем проверяем matchPatterns (для вложенных путей)
//     for (final destination in DashboardDestination.values) {
//       for (final pattern in destination.matchPatterns) {
//         if (location.startsWith(pattern)) {
//           return destination;
//         }
//       }
//     }

//     return DashboardDestination.home;
//   }

//   /// Проверить, соответствует ли путь этому destination
//   bool matchesPath(String location) {
//     if (location == path) return true;
//     return matchPatterns.any((pattern) => location.startsWith(pattern));
//   }

//   // ===========================================================================
//   // Widget Builders
//   // ===========================================================================

//   /// Конвертировать в [NavigationRailDestination] для desktop
//   NavigationRailDestination toRailDestination() {
//     return NavigationRailDestination(
//       icon: Icon(icon),
//       selectedIcon: Icon(selectedIcon),
//       label: Text(label),
//     );
//   }

//   /// Конвертировать в [BottomNavigationBarItem] для mobile
//   BottomNavigationBarItem toBottomNavItem() {
//     return BottomNavigationBarItem(
//       icon: Icon(icon),
//       activeIcon: Icon(selectedIcon),
//       label: label,
//     );
//   }

//   // ===========================================================================
//   // Utility Methods
//   // ===========================================================================

//   /// Получить все destinations для NavigationRail
//   static List<NavigationRailDestination> toRailDestinations({
//     DestinationVisibilityCallback? isVisible,
//     BuildContext? context,
//   }) {
//     var destinations = DashboardDestination.values;

//     // Фильтруем по видимости если передан callback и context
//     if (isVisible != null && context != null) {
//       destinations = destinations.where((d) => isVisible(context)).toList();
//     }

//     return destinations.map((d) => d.toRailDestination()).toList();
//   }

//   /// Получить все destinations для BottomNavigationBar
//   static List<BottomNavigationBarItem> toBottomNavItems({
//     DestinationVisibilityCallback? isVisible,
//     BuildContext? context,
//   }) {
//     var destinations = DashboardDestination.values;

//     // Фильтруем по видимости если передан callback и context
//     if (isVisible != null && context != null) {
//       destinations = destinations.where((d) => isVisible(context)).toList();
//     }

//     return destinations.map((d) => d.toBottomNavItem()).toList();
//   }

//   @override
//   String toString() => 'DashboardDestination.$name(index: $index, path: $path)';
// }
