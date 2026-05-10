import "package:freezed_annotation/freezed_annotation.dart";

import 'entity_type.dart';

part 'dashboard_list_refresh_state.freezed.dart';

enum DataRefreshType { add, update, delete }

@freezed
sealed class DashboardListRefreshState with _$DashboardListRefreshState {
  const factory DashboardListRefreshState({
    required DataRefreshType type,
    required DateTime timestamp,
    String? entityId,
    EntityType? entityType,
    Map<String, dynamic>? data,
  }) = _DashboardListRefreshState;
}
