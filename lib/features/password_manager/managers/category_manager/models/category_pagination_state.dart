import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';

part 'category_pagination_state.freezed.dart';

@freezed
@immutable
sealed class CategoryPaginationState with _$CategoryPaginationState {
  const factory CategoryPaginationState({
    required List<CategoryCardDto> items,
    required bool hasMore,
    required bool isLoading,
    required Object? error,
    required int currentPage,
    required int totalCount,
  }) = _CategoryPaginationState;

  factory CategoryPaginationState.initial() {
    return const CategoryPaginationState(
      items: [],
      hasMore: true,
      isLoading: false,
      error: null,
      currentPage: 0,
      totalCount: 0,
    );
  }
}
