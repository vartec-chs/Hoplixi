import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_manager_filter.freezed.dart';

enum TagManagerSortField {
  name,
  createdAt,
  modifiedAt,
}

@freezed
sealed class TagManagerFilter with _$TagManagerFilter {
  const TagManagerFilter._();

  const factory TagManagerFilter({
    @Default('') String query,
    int? color,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    @Default(TagManagerSortField.name) TagManagerSortField sortField,
    @Default(30) int limit,
    @Default(0) int offset,
  }) = _TagManagerFilter;

  factory TagManagerFilter.initial() => const TagManagerFilter();
}
