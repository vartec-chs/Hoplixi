import 'package:flutter/material.dart';

const dashboardShowcaseScope = 'dashboard_guide';

class DashboardGuideKeys {
  final navigation = GlobalKey();
  final search = GlobalKey();
  final entityTypeSelector = GlobalKey();
  final filters = GlobalKey();
  final createItem = GlobalKey();
  final syncStatus = GlobalKey();

  List<GlobalKey> get sequence => [
    navigation,
    search,
    entityTypeSelector,
    filters,
    createItem,
    syncStatus,
  ];
}

class DashboardGuideScope extends InheritedWidget {
  const DashboardGuideScope({
    super.key,
    required this.guideKeys,
    required super.child,
  });

  final DashboardGuideKeys guideKeys;

  static DashboardGuideKeys? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DashboardGuideScope>()
        ?.guideKeys;
  }

  @override
  bool updateShouldNotify(DashboardGuideScope oldWidget) {
    return guideKeys != oldWidget.guideKeys;
  }
}
