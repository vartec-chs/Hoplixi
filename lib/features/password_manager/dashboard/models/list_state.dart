import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

part 'list_state.freezed.dart';

@freezed
@immutable
abstract class DashboardListState<T extends BaseCardDto>
    with _$DashboardListState<T> {
  const factory DashboardListState({
    @Default([]) List<T> items,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(true) bool hasMore,
    String? error,
    @Default(0) int currentPage,
    @Default(0) int totalCount,
  }) = _DashboardListState<T>;
}
