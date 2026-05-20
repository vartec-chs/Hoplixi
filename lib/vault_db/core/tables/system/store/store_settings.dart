import 'package:drift/drift.dart';

enum StoreSettingValueType { string, int, double, bool, json }

@DataClassName('StoreSettingData')
class StoreSettings extends Table {
  /// Ключ настройки.
  ///
  /// Например:
  /// - history_secrets_mode
  /// - history_enabled
  TextColumn get key => text().withLength(min: 1, max: 255)();

  /// Значение настройки как строка.
  ///
  /// Для bool лучше хранить 'true' / 'false',
  /// чтобы триггерам было удобно читать.
  TextColumn get value => text()();

  /// Тип значения.
  TextColumn get valueType =>
      textEnum<StoreSettingValueType>().withDefault(const Constant('string'))();

  /// Описание/комментарий к настройке.
  TextColumn get description => text().nullable()();

  /// Дата создания настройки.
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  /// Дата последнего изменения настройки.
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {key};

  @override
  String get tableName => 'store_settings';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${StoreSettingConstraint.keyNotBlank.constraintName}
    CHECK (
      length(trim(key)) > 0
    )
    ''',

    '''
    CONSTRAINT ${StoreSettingConstraint.valueNotBlank.constraintName}
    CHECK (
      length(trim(value)) > 0
    )
    ''',

    '''
    CONSTRAINT ${StoreSettingConstraint.descriptionNotBlank.constraintName}
    CHECK (
      description IS NULL
      OR length(trim(description)) > 0
    )
    ''',
  ];
}

enum StoreSettingConstraint {
  keyNotBlank('chk_store_settings_key_not_blank'),

  valueNotBlank('chk_store_settings_value_not_blank'),

  descriptionNotBlank('chk_store_settings_description_not_blank');

  const StoreSettingConstraint(this.constraintName);

  final String constraintName;
}

enum StoreSettingIndex {
  valueType('idx_store_settings_value_type'),
  modifiedAt('idx_store_settings_modified_at');

  const StoreSettingIndex(this.indexName);

  final String indexName;
}

final List<String> storeSettingsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${StoreSettingIndex.valueType.indexName} ON store_settings(value_type);',
  'CREATE INDEX IF NOT EXISTS ${StoreSettingIndex.modifiedAt.indexName} ON store_settings(modified_at);',
];
