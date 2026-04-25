import 'package:freezed_annotation/freezed_annotation.dart';

part 'icons_filter.freezed.dart';
part 'icons_filter.g.dart';

enum IconsSortField { name, type, createdAt, modifiedAt }

@freezed
abstract class IconsFilter with _$IconsFilter {
  const factory IconsFilter({
    @Default('') String query,
    String? type,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    @Default(IconsSortField.name) IconsSortField sortField,
    @Default(0) int? limit,
    @Default(0) int? offset,
  }) = _IconsFilter;

  factory IconsFilter.create({
    String? query,
    String? type,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    IconsSortField? sortField,
    int? limit,
    int? offset,
  }) {
    final normalizedQuery = (query ?? '').trim();
    final normalizedType = type?.trim();

    return IconsFilter(
      query: normalizedQuery,
      type: normalizedType?.isEmpty == true ? null : normalizedType,
      createdAfter: createdAfter,
      createdBefore: createdBefore,
      modifiedAfter: modifiedAfter,
      modifiedBefore: modifiedBefore,
      sortField: sortField ?? IconsSortField.name,
      limit: limit,
      offset: offset,
    );
  }

  factory IconsFilter.fromJson(Map<String, dynamic> json) =>
      _$IconsFilterFromJson(json);
}

extension IconsFilterHelpers on IconsFilter {
  /// Проверяет наличие активных ограничений фильтра
  bool get hasActiveConstraints {
    if (query.isNotEmpty) return true;
    if (type != null) return true;
    if (createdAfter != null || createdBefore != null) return true;
    if (modifiedAfter != null || modifiedBefore != null) return true;
    return false;
  }
}
