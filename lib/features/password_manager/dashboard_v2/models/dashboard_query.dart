import 'dashboard_entity_type.dart';
import 'dashboard_filter_state.dart';

final class DashboardQuery {
  const DashboardQuery({
    required this.entityType,
    required this.filters,
    required this.page,
  });

  final DashboardEntityType entityType;
  final DashboardFilterState filters;
  final int page;
}
