import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';

part 'tags_filter.freezed.dart';
part 'tags_filter.g.dart';

enum TagsSortField { name, type, createdAt, modifiedAt }

@freezed
abstract class TagsFilter with _$TagsFilter {
  const factory TagsFilter({
    @Default('') String query,
    @Default([])  List<TagType?> types,
    String? color,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    @Default(TagsSortField.name) TagsSortField sortField,
    @Default(0) int? limit,
    @Default(0) int? offset,
  }) = _TagsFilter;

  factory TagsFilter.create({
    String? query,
    List<TagType?>? types,
    String? color,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    TagsSortField? sortField,
    int? limit,
    int? offset,
  }) {
    final normalizedQuery = (query ?? '').trim();
  
    final normalizedColor = color?.trim();

    return TagsFilter(
      query: normalizedQuery,
      types: types ?? [],
      color: normalizedColor?.isEmpty == true ? null : normalizedColor,
      createdAfter: createdAfter,
      createdBefore: createdBefore,
      modifiedAfter: modifiedAfter,
      modifiedBefore: modifiedBefore,
      sortField: sortField ?? TagsSortField.name,
      limit: limit,
      offset: offset,
    );
  }

  factory TagsFilter.fromJson(Map<String, dynamic> json) =>
      _$TagsFilterFromJson(json);
}

extension TagsFilterHelpers on TagsFilter {
  /// Проверяет наличие активных ограничений фильтра
  bool get hasActiveConstraints {
    if (query.isNotEmpty) return true;
    if (types.isNotEmpty) return true;
    if (color != null) return true;
    if (createdAfter != null || createdBefore != null) return true;
    if (modifiedAfter != null || modifiedBefore != null) return true;
    return false;
  }

  /// Проверка валидности hex цвета
  bool get isValidColor {
    if (color == null || color!.isEmpty) return true;
    final colorRegex = RegExp(r'^[0-9A-Fa-f]{6}$');
    return colorRegex.hasMatch(color!);
  }
}
