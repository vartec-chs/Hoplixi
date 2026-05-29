import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

part 'icon_pagination_state.freezed.dart';

@freezed
@immutable
sealed class IconPaginationState with _$IconPaginationState {
  const factory IconPaginationState({
    required List<CustomIconCardDto> items,
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
