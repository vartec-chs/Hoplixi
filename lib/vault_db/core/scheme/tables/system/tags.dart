import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

enum TagType {
  note,
  password,
  otp,
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

  /// Тип тега: password, note, otp, mixed и т.д.
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
    CONSTRAINT ${TagConstraint.idNotBlank.constraintName}
    CHECK (
      length(trim(id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${TagConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${TagConstraint.nameNoOuterWhitespace.constraintName}
    CHECK (
      name = trim(name)
    )
    ''',

    '''
    CONSTRAINT ${TagConstraint.colorNotBlank.constraintName}
    CHECK (
      color IS NULL
      OR length(trim(color)) > 0
    )
    ''',

    '''
    CONSTRAINT ${TagConstraint.colorNoOuterWhitespace.constraintName}
    CHECK (
      color IS NULL
      OR color = trim(color)
    )
    ''',

    '''
    CONSTRAINT ${TagConstraint.modifiedAtAfterCreatedAt.constraintName}
    CHECK (
      modified_at >= created_at
    )
    ''',
  ];
}

enum TagConstraint {
  idNotBlank('chk_tags_id_not_blank'),

  nameNotBlank('chk_tags_name_not_blank'),

  nameNoOuterWhitespace('chk_tags_name_no_outer_whitespace'),

  colorNotBlank('chk_tags_color_not_blank'),

  colorNoOuterWhitespace('chk_tags_color_no_outer_whitespace'),

  modifiedAtAfterCreatedAt('chk_tags_modified_at_after_created_at');

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

enum TagTrigger {
  preventCreatedAtUpdate('trg_tags_prevent_created_at_update');

  const TagTrigger(this.triggerName);

  final String triggerName;
}

enum TagRaise {
  createdAtImmutable('tags.created_at is immutable');

  const TagRaise(this.message);

  final String message;
}

final List<String> tagsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${TagTrigger.preventCreatedAtUpdate.triggerName}
  BEFORE UPDATE OF created_at ON tags
  FOR EACH ROW
  WHEN NEW.created_at <> OLD.created_at
  BEGIN
    SELECT RAISE(
      ABORT,
      '${TagRaise.createdAtImmutable.message}'
    );
  END;
  ''',
];
