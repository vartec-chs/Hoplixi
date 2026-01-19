import "package:freezed_annotation/freezed_annotation.dart";
import "package:hoplixi/features/password_manager/dashboard/models/entity_type.dart";

part 'data_refresh_state.freezed.dart';

enum DataRefreshType { add, update, delete }

@freezed
sealed class DataRefreshState with _$DataRefreshState {
  const factory DataRefreshState({
    required DataRefreshType type,
    required DateTime timestamp,
    String? entityId,
    EntityType? entityType,
    Map<String, dynamic>? data,
  }) = _DataRefreshState;
}
