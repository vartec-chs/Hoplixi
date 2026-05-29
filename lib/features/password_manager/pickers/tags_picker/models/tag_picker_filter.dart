enum TagType {
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

  const TagType(this.value);

  final String value;
}

enum TagsSortField { name, createdAt, modifiedAt }

class TagPickerFilter {
  const TagPickerFilter({
    this.query = '',
    this.types = const [],
    this.color,
    this.createdAfter,
    this.createdBefore,
    this.modifiedAfter,
    this.modifiedBefore,
    this.sortField = TagsSortField.name,
  });

  final String query;
  final List<TagType?> types;
  final String? color;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final DateTime? modifiedAfter;
  final DateTime? modifiedBefore;
  final TagsSortField sortField;

  TagPickerFilter copyWith({
    String? query,
    List<TagType?>? types,
    String? color,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    TagsSortField? sortField,
  }) {
    return TagPickerFilter(
      query: query ?? this.query,
      types: types ?? this.types,
      color: color ?? this.color,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      modifiedAfter: modifiedAfter ?? this.modifiedAfter,
      modifiedBefore: modifiedBefore ?? this.modifiedBefore,
      sortField: sortField ?? this.sortField,
    );
  }
}
