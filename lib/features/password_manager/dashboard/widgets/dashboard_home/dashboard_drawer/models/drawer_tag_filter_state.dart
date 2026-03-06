import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'drawer_tag_filter_state.freezed.dart';

@freezed
sealed class DrawerTagFilterState with _$DrawerTagFilterState {
  const factory DrawerTagFilterState({
    @Default(<TagCardDto>[]) List<TagCardDto> tags,
    @Default(<String>[]) List<String> selectedIds,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    @Default(0) int offset,
    @Default('') String searchQuery,
  }) = _DrawerTagFilterState;
}
