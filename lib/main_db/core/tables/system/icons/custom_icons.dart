import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

enum CustomIconFormat { png, jpg, jpeg, svg, webp, gif }

@DataClassName('CustomIconsData')
class CustomIcons extends Table {
  /// UUID v4.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Название пользовательской иконки.
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// Формат иконки: png, jpg, jpeg, svg, webp, gif.
  TextColumn get format => textEnum<CustomIconFormat>()();

  /// Binary image data.
  ///
  /// Иконка предварительно нормализуется приложением,
  /// например обрезается/масштабируется до 256x256.
  BlobColumn get data => blob()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'custom_icons';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${CustomIconConstraint.idNotBlank.constraintName}
    CHECK (
      length(trim(id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CustomIconConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CustomIconConstraint.nameNoOuterWhitespace.constraintName}
    CHECK (
      name = trim(name)
    )
    ''',

    '''
    CONSTRAINT ${CustomIconConstraint.dataNotEmpty.constraintName}
    CHECK (
      length(data) > 0
    )
    ''',

    '''
    CONSTRAINT ${CustomIconConstraint.modifiedAtAfterCreatedAt.constraintName}
    CHECK (
      modified_at >= created_at
    )
    ''',
  ];
}

enum CustomIconConstraint {
  idNotBlank('chk_custom_icons_id_not_blank'),

  nameNotBlank('chk_custom_icons_name_not_blank'),

  nameNoOuterWhitespace('chk_custom_icons_name_no_outer_whitespace'),

  dataNotEmpty('chk_custom_icons_data_not_empty'),

  modifiedAtAfterCreatedAt('chk_custom_icons_modified_at_after_created_at');

  const CustomIconConstraint(this.constraintName);

  final String constraintName;
}

enum CustomIconIndex {
  name('idx_custom_icons_name'),
  format('idx_custom_icons_format');

  const CustomIconIndex(this.indexName);

  final String indexName;
}

final List<String> customIconsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${CustomIconIndex.name.indexName} ON custom_icons(name);',
  'CREATE INDEX IF NOT EXISTS ${CustomIconIndex.format.indexName} ON custom_icons(format);',
];

enum CustomIconTrigger {
  preventCreatedAtUpdate('trg_custom_icons_prevent_created_at_update');

  const CustomIconTrigger(this.triggerName);

  final String triggerName;
}

enum CustomIconRaise {
  createdAtImmutable('custom_icons.created_at is immutable');

  const CustomIconRaise(this.message);

  final String message;
}

final List<String> customIconsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${CustomIconTrigger.preventCreatedAtUpdate.triggerName}
  BEFORE UPDATE OF created_at ON custom_icons
  FOR EACH ROW
  WHEN NEW.created_at <> OLD.created_at
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CustomIconRaise.createdAtImmutable.message}'
    );
  END;
  ''',
];
