import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'tag_picker_state.freezed.dart';

@freezed
@immutable
sealed class TagPickerState with _$TagPickerState {
  const factory TagPickerState({
    required List<TagCardDto> tags,
    required bool isLoading,
    required TagPaginationState pagination,
  }) = _TagPickerState;

  factory TagPickerState.initial() {
    return TagPickerState(
      tags: const [],
      isLoading: false,
      pagination: TagPaginationState.initial(),
    );
  }
}

@freezed
@immutable
sealed class TagPaginationState with _$TagPaginationState {
  const factory TagPaginationState({
    required bool hasMore,
    required int currentPage,
  }) = _TagPaginationState;

  factory TagPaginationState.initial() {
    return const TagPaginationState(hasMore: true, currentPage: 0);
  }
}
