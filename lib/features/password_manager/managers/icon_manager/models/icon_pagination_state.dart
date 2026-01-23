import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/main_store.dart';

part 'icon_pagination_state.freezed.dart';

@freezed
@immutable
sealed class IconPaginationState with _$IconPaginationState {
  const factory IconPaginationState({
    required List<IconsData> items,
    required bool hasMore,
    required bool isLoading,
    required Object? error,
    required int currentPage,
    required int totalCount,
  }) = _IconPaginationState;

  factory IconPaginationState.initial() {
    return const IconPaginationState(
      items: [],
      hasMore: true,
      isLoading: false,
      error: null,
      currentPage: 0,
      totalCount: 0,
    );
  }
}
