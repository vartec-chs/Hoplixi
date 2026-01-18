import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'drawer_filter_state.freezed.dart';
part 'drawer_filter_state.g.dart';

@freezed
sealed class DrawerFilterState with _$DrawerFilterState {
  const factory DrawerFilterState({
    @Default(<String>[]) List<String> selectedCategoryIds,
    @Default(<String>[]) List<String> selectedTagIds,

    @Default(<CategoryCardDto>[]) List<CategoryCardDto> categories,
    @Default(<TagCardDto>[]) List<TagCardDto> tags,

    @Default(false) bool isCategoriesLoading,
    @Default(false) bool hasMoreCategories,
    @Default(0) int categoriesOffset,

    @Default(false) bool isTagsLoading,
    @Default(false) bool hasMoreTags,
    @Default(0) int tagsOffset,

    @Default('') String categorySearchQuery,
    @Default('') String tagSearchQuery,
  }) = _DrawerFilterState;

  factory DrawerFilterState.fromJson(Map<String, dynamic> json) =>
      _$DrawerFilterStateFromJson(json);
}
