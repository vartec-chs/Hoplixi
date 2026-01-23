import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';

part 'category_picker_state.freezed.dart';

@freezed
sealed class CategoryPickerState with _$CategoryPickerState {
  const factory CategoryPickerState({
    @Default([]) List<CategoryCardDto> categories,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    @Default(0) int currentPage,
    @Default('') String searchQuery,
    String? selectedTypeFilter,
    String? selectedCategoryId,
    String? error,
  }) = _CategoryPickerState;
}
