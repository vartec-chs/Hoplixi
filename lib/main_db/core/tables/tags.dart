import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

enum TagType {
  note,
  password,
  totp,
  bankCard,
  file,
  document,
  contact,
  apiKey,
  sshKey,
  certificate,
  cryptoWallet,
  wifi,
  identity,
  licenseKey,
  recoveryCodes,
  loyaltyCard,
  mixed,
}

@DataClassName('TagsData')
class Tags extends Table {
  /// UUID v4.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Название тега.
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Цвет тега в формате AARRGGBB.
  TextColumn get color => text()
      .withLength(min: 8, max: 8)
      .withDefault(const Constant('FFFFFFFF'))();

  /// Тип тега: password, note, totp, mixed и т.д.
  TextColumn get type => textEnum<TagType>()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {name, type},
  ];

  @override
  String get tableName => 'tags';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${TagConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${TagConstraint.colorArgbHex.constraintName}
    CHECK (
      color GLOB '[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]'
    )
    ''',
  ];
}

enum TagConstraint {
  nameNotBlank('chk_tags_name_not_blank'),

  colorArgbHex('chk_tags_color_argb_hex');

  const TagConstraint(this.constraintName);

  final String constraintName;
}

enum TagIndex {
  name('idx_tags_name'),
  type('idx_tags_type'),
  color('idx_tags_color'),
  createdAt('idx_tags_created_at'),
  modifiedAt('idx_tags_modified_at');

  const TagIndex(this.indexName);

  final String indexName;
}

final List<String> tagsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${TagIndex.name.indexName} ON tags(name);',
  'CREATE INDEX IF NOT EXISTS ${TagIndex.type.indexName} ON tags(type);',
  'CREATE INDEX IF NOT EXISTS ${TagIndex.color.indexName} ON tags(color);',
  'CREATE INDEX IF NOT EXISTS ${TagIndex.createdAt.indexName} ON tags(created_at);',
  'CREATE INDEX IF NOT EXISTS ${TagIndex.modifiedAt.indexName} ON tags(modified_at);',
];
