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
    CONSTRAINT ${CustomIconConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',
  ];
}

enum CustomIconConstraint {
  nameNotBlank('chk_custom_icons_name_not_blank');

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
