import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_filter_state.dart';
import '../models/dashboard_filter_tab.dart';
import '../models/dashboard_view_mode.dart';

final dashboardFilterProvider =
    NotifierProvider<DashboardFilterNotifier, DashboardFilterState>(
      DashboardFilterNotifier.new,
    );

final class DashboardFilterNotifier extends Notifier<DashboardFilterState> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  DashboardFilterState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const DashboardFilterState();
  }

  void setQuery(String query) {
    final normalizedQuery = query.trim();

    _debounceTimer?.cancel();

    if (normalizedQuery.isEmpty) {
      state = state.copyWith(query: normalizedQuery);
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () {
      state = state.copyWith(query: normalizedQuery);
      _debounceTimer = null;
    });
  }

  void setTab(DashboardFilterTab tab) {
    state = state.copyWith(tab: tab);
  }

  void setViewMode(DashboardViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
  }
}
