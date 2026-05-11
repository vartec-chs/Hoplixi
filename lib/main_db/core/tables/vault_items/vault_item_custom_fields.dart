import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'vault_items.dart';

enum CustomFieldType {
  /// Обычный текст.
  text,

  /// Скрытое/чувствительное значение.
  concealed,

  /// URL-адрес.
  url,

  /// Email.
  email,

  /// Номер телефона.
  phone,

  /// Дата.
  date,

  /// Числовое значение.
  number,

  /// Многострочный текст.
  multiline,

  /// Boolean/checkbox.
  boolean,

  /// JSON/string для сложных значений.
  json,

  /// Прочее.
  other,
}

@DataClassName('VaultItemCustomFieldsData')
class VaultItemCustomFields extends Table {
  /// Уникальный идентификатор кастомного поля UUID v4.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// FK → vault_items.id ON DELETE CASCADE.
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Отображаемое название поля.
  ///
  /// Например: PIN, Recovery URL, Customer ID.
  TextColumn get label => text().withLength(min: 1, max: 255)();

  /// Значение поля.
  ///
  /// Для CustomFieldType.concealed это чувствительное значение.
  /// В текущей модели БД оно хранится внутри зашифрованной SQLite-БД.
  TextColumn get value => text().nullable()();

  /// Тип поля.
  TextColumn get fieldType =>
      textEnum<CustomFieldType>().withDefault(const Constant('text'))();

  /// Дополнительный тип поля, если fieldType = other.
  TextColumn get fieldTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Порядок отображения поля.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Дополнительные метаданные в JSON-формате.
  ///
  /// Например: placeholder, validationRule, source, importInfo,
  /// displayMode, copiedCount.
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_item_custom_fields';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${VaultItemCustomFieldConstraint.labelNotBlank.constraintName}
    CHECK (
      length(trim(label)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemCustomFieldConstraint.valueNotBlank.constraintName}
    CHECK (
      value IS NULL
      OR length(trim(value)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemCustomFieldConstraint.fieldTypeOtherRequired.constraintName}
    CHECK (
      field_type != 'other'
      OR (
        field_type_other IS NOT NULL
        AND length(trim(field_type_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${VaultItemCustomFieldConstraint.fieldTypeOtherMustBeNull.constraintName}
    CHECK (
      field_type = 'other'
      OR field_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${VaultItemCustomFieldConstraint.sortOrderNonNegative.constraintName}
    CHECK (
      sort_order >= 0
    )
    ''',
  ];
}

enum VaultItemCustomFieldConstraint {
  labelNotBlank(
    'chk_vault_item_custom_fields_label_not_blank',
  ),

  valueNotBlank(
    'chk_vault_item_custom_fields_value_not_blank',
  ),

  fieldTypeOtherRequired(
    'chk_vault_item_custom_fields_field_type_other_required',
  ),

  fieldTypeOtherMustBeNull(
    'chk_vault_item_custom_fields_field_type_other_must_be_null',
  ),

  sortOrderNonNegative(
    'chk_vault_item_custom_fields_sort_order_non_negative',
  );

  const VaultItemCustomFieldConstraint(this.constraintName);

  final String constraintName;
}

enum VaultItemCustomFieldIndex {
  itemId('idx_vault_item_custom_fields_item_id'),
  fieldType('idx_vault_item_custom_fields_field_type'),
  sortOrder('idx_vault_item_custom_fields_sort_order'),
  itemSortOrder('idx_vault_item_custom_fields_item_id_sort_order');

  const VaultItemCustomFieldIndex(this.indexName);

  final String indexName;
}

final List<String> vaultItemCustomFieldsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldIndex.itemId.indexName} ON vault_item_custom_fields(item_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldIndex.fieldType.indexName} ON vault_item_custom_fields(field_type);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldIndex.sortOrder.indexName} ON vault_item_custom_fields(sort_order);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldIndex.itemSortOrder.indexName} ON vault_item_custom_fields(item_id, sort_order);',
];