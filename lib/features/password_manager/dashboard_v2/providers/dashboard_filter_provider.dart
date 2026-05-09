import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_filter_state.dart';
import '../models/dashboard_filter_tab.dart';
import '../models/dashboard_view_mode.dart';

final dashboardFilterProvider =
    NotifierProvider<DashboardFilterNotifier, DashboardFilterState>(
      DashboardFilterNotifier.new,
    );

final class DashboardFilterNotifier extends Notifier<DashboardFilterState> {
  @override
  DashboardFilterState build() => const DashboardFilterState();

  void setQuery(String query) {
    state = state.copyWith(query: query.trim());
  }

  void setTab(DashboardFilterTab tab) {
    state = state.copyWith(tab: tab);
  }

  void setViewMode(DashboardViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
  }
}
