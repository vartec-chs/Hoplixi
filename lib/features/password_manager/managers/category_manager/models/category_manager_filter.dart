import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_manager_filter.freezed.dart';

enum CategoryManagerSortField {
  name,
  createdAt,
  modifiedAt,
}

@freezed
sealed class CategoryManagerFilter with _$CategoryManagerFilter {
  const CategoryManagerFilter._();

  const factory CategoryManagerFilter({
    @Default('') String query,
    int? color,
    bool? hasIcon,
    bool? hasDescription,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    @Default(CategoryManagerSortField.name) CategoryManagerSortField sortField,
    @Default(30) int limit,
    @Default(0) int offset,
  }) = _CategoryManagerFilter;

  factory CategoryManagerFilter.initial() => const CategoryManagerFilter();

  bool get hasActiveConstraints =>
      query.isNotEmpty ||
      color != null ||
      hasIcon != null ||
      hasDescription != null ||
      createdAfter != null ||
      createdBefore != null ||
      modifiedAfter != null ||
      modifiedBefore != null;
}
