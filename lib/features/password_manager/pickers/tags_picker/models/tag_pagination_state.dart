import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'tag_pagination_state.freezed.dart';

@freezed
@immutable
sealed class TagPaginationState with _$TagPaginationState {
  const factory TagPaginationState({
    required List<TagCardDto> items,
    required bool hasMore,
    required bool isLoading,
    required Object? error,
    required int currentPage,
    required int totalCount,
  }) = _TagPaginationState;

  factory TagPaginationState.initial() {
    return const TagPaginationState(
      items: [],
      hasMore: true,
      isLoading: false,
      error: null,
      currentPage: 0,
      totalCount: 0,
    );
  }
}
