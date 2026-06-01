import 'package:freezed_annotation/freezed_annotation.dart';

part 'icon_manager_filter.freezed.dart';

enum IconManagerSortField { name, createdAt, modifiedAt }

@freezed
sealed class IconManagerFilter with _$IconManagerFilter {
  const IconManagerFilter._();

  const factory IconManagerFilter({
    @Default('') String query,
    String? type,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    @Default(IconManagerSortField.name) IconManagerSortField sortField,
    @Default(30) int limit,
    @Default(0) int offset,
  }) = _IconManagerFilter;

  factory IconManagerFilter.initial() => const IconManagerFilter();
}
