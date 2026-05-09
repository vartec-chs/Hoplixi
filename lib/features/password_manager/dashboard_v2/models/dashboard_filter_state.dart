import 'dashboard_filter_tab.dart';
import 'dashboard_view_mode.dart';

final class DashboardFilterState {
  const DashboardFilterState({
    this.query = '',
    this.tab = DashboardFilterTab.active,
    this.viewMode = DashboardViewMode.list,
    this.pageSize = 30,
  });

  final String query;
  final DashboardFilterTab tab;
  final DashboardViewMode viewMode;
  final int pageSize;

  DashboardFilterState copyWith({
    String? query,
    DashboardFilterTab? tab,
    DashboardViewMode? viewMode,
    int? pageSize,
  }) {
    return DashboardFilterState(
      query: query ?? this.query,
      tab: tab ?? this.tab,
      viewMode: viewMode ?? this.viewMode,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
