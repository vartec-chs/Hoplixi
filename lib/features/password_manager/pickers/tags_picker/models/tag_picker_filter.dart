enum TagsSortField { name, createdAt, modifiedAt }

class TagPickerFilter {
  const TagPickerFilter({
    this.query = '',
    this.color,
    this.createdAfter,
    this.createdBefore,
    this.modifiedAfter,
    this.modifiedBefore,
    this.sortField = TagsSortField.name,
  });

  final String query;
  final String? color;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final DateTime? modifiedAfter;
  final DateTime? modifiedBefore;
  final TagsSortField sortField;

  TagPickerFilter copyWith({
    String? query,
    String? color,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    TagsSortField? sortField,
  }) {
    return TagPickerFilter(
      query: query ?? this.query,
      color: color ?? this.color,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      modifiedAfter: modifiedAfter ?? this.modifiedAfter,
      modifiedBefore: modifiedBefore ?? this.modifiedBefore,
      sortField: sortField ?? this.sortField,
    );
  }
}
