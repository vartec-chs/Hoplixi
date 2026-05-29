enum CategoryType {
  note('note'),
  password('password'),
  totp('totp'),
  bankCard('bankCard'),
  file('file'),
  document('document'),
  contact('contact'),
  apiKey('apiKey'),
  sshKey('sshKey'),
  certificate('certificate'),
  cryptoWallet('cryptoWallet'),
  wifi('wifi'),
  identity('identity'),
  licenseKey('licenseKey'),
  recoveryCodes('recoveryCodes'),
  loyaltyCard('loyaltyCard'),
  mixed('mixed');

  const CategoryType(this.value);

  final String value;

  static CategoryType? fromString(String value) {
    for (final type in values) {
      if (type.value == value || type.name == value) {
        return type;
      }
    }
    return null;
  }
}

enum CategoriesSortField { name, createdAt, modifiedAt }

class CategoryPickerFilter {
  const CategoryPickerFilter({
    this.query = '',
    this.types = const [],
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
  final List<CategoryType?> types;
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
    List<CategoryType?>? types,
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
      types: types ?? this.types,
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
