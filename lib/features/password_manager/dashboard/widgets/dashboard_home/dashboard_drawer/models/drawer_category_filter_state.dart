import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';

part 'drawer_category_filter_state.freezed.dart';

@freezed
sealed class DrawerCategoryFilterState with _$DrawerCategoryFilterState {
  const factory DrawerCategoryFilterState({
    @Default(<CategoryCardDto>[]) List<CategoryCardDto> categories,
    @Default(<String>[]) List<String> selectedIds,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    @Default(0) int offset,
    @Default('') String searchQuery,
  }) = _DrawerCategoryFilterState;
}
