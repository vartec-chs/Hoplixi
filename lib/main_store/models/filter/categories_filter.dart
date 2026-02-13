import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';

part 'categories_filter.freezed.dart';
part 'categories_filter.g.dart';

enum CategoriesSortField { name, type, createdAt, modifiedAt }

@freezed
@immutable
abstract class CategoriesFilter with _$CategoriesFilter {
  const factory CategoriesFilter({
    @Default('') String query,
    @Default([]) List<CategoryType?> types,
    String? color,
    bool? hasIcon,
    bool? hasDescription,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    @Default(CategoriesSortField.name) CategoriesSortField sortField,
    @Default(0) int? limit,
    @Default(0) int? offset,
  }) = _CategoriesFilter;

  factory CategoriesFilter.create({
    String? query,
    List<CategoryType?>? types,
    String? color,
    bool? hasIcon,
    bool? hasDescription,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    CategoriesSortField? sortField,
    int? limit,
    int? offset,
  }) {
    final normalizedQuery = (query ?? '').trim();

    final normalizedColor = color?.trim();

    return CategoriesFilter(
      query: normalizedQuery,
      types: types ?? [],
      color: normalizedColor?.isEmpty == true ? null : normalizedColor,
      hasIcon: hasIcon,
      hasDescription: hasDescription,
      createdAfter: createdAfter,
      createdBefore: createdBefore,
      modifiedAfter: modifiedAfter,
      modifiedBefore: modifiedBefore,
      sortField: sortField ?? CategoriesSortField.name,
      limit: limit,
      offset: offset,
    );
  }

  factory CategoriesFilter.fromJson(Map<String, dynamic> json) =>
      _$CategoriesFilterFromJson(json);
}

extension CategoriesFilterHelpers on CategoriesFilter {
  /// Проверяет наличие активных ограничений фильтра
  bool get hasActiveConstraints {
    if (query.isNotEmpty) return true;
    if (types.isNotEmpty) return true;
    if (color != null) return true;
    if (hasIcon != null) return true;
    if (hasDescription != null) return true;
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
