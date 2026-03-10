import 'package:flutter/material.dart';

/// InheritedWidget, предоставляющий доступ к функциям Drawer
/// для потомков, находящихся вне Scaffold (например, Navigator content
/// в MobileDashboardLayout).
class DashboardDrawerScope extends InheritedWidget {
  const DashboardDrawerScope({
    required this.openDrawer,
    required super.child,
    super.key,
  });

  /// Callback для открытия drawer.
  final VoidCallback openDrawer;

  static DashboardDrawerScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DashboardDrawerScope>();
  }

  @override
  bool updateShouldNotify(DashboardDrawerScope oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}
