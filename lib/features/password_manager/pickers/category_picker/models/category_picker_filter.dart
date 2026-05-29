enum CategoriesSortField { name, createdAt, modifiedAt }

class CategoryPickerFilter {
  const CategoryPickerFilter({
    this.query = '',
    this.color,
    this.hasIcon,
    this.hasDescription,
    this.createdAfter,
    this.createdBefore,
    this.modifiedAfter,
    this.modifiedBefore,
    this.sortField = CategoriesSortField.name,
  });

  final String query;
  final String? color;
  final bool? hasIcon;
  final bool? hasDescription;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final DateTime? modifiedAfter;
  final DateTime? modifiedBefore;
  final CategoriesSortField sortField;

  CategoryPickerFilter copyWith({
    String? query,
    String? color,
    bool? hasIcon,
    bool? hasDescription,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    CategoriesSortField? sortField,
  }) {
    return CategoryPickerFilter(
      query: query ?? this.query,
      color: color ?? this.color,
      hasIcon: hasIcon ?? this.hasIcon,
      hasDescription: hasDescription ?? this.hasDescription,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      modifiedAfter: modifiedAfter ?? this.modifiedAfter,
      modifiedBefore: modifiedBefore ?? this.modifiedBefore,
      sortField: sortField ?? this.sortField,
    );
  }
}
