import 'entity_type.dart';
import 'dashboard_filter_state.dart';

final class DashboardQuery {
  const DashboardQuery({
    required this.entityType,
    required this.filters,
    required this.entityFilter,
    required this.page,
  });

  final EntityType entityType;
  final DashboardFilterState filters;
  final Object entityFilter;
  final int page;
}
