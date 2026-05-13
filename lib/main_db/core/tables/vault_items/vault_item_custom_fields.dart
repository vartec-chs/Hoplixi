import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'vault_items.dart';

enum CustomFieldType {
  text,
  concealed,
  url,
  email,
  phone,
  date,
  number,
  multiline,
  boolean,
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
  /// Для CustomFieldType.concealed или isSecret = true
  /// это чувствительное значение.
  TextColumn get value => text().nullable()();

  /// Тип поля.
  TextColumn get fieldType =>
      textEnum<CustomFieldType>().withDefault(const Constant('text'))();

  /// Быстрый флаг секретности поля.
  ///
  /// Не заменяет VaultSecretFieldRegistry, но упрощает UI, поиск и экспорт.
  BoolColumn get isSecret => boolean().withDefault(const Constant(false))();

  /// Порядок отображения поля внутри item.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Дата создания custom field.
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  /// Дата последнего изменения custom field.
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_item_custom_fields';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${VaultItemCustomFieldConstraint.idNotBlank.constraintName}
        CHECK (
          length(trim(id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldConstraint.itemIdNotBlank.constraintName}
        CHECK (
          length(trim(item_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldConstraint.labelNotBlank.constraintName}
        CHECK (
          length(trim(label)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldConstraint.labelNoOuterWhitespace.constraintName}
        CHECK (
          label = trim(label)
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
        CONSTRAINT ${VaultItemCustomFieldConstraint.booleanValueFormat.constraintName}
        CHECK (
          field_type != 'boolean'
          OR value IS NULL
          OR value IN ('true', 'false')
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldConstraint.dateValueFormat.constraintName}
        CHECK (
          field_type != 'date'
          OR value IS NULL
          OR (
            length(value) = 10
            AND value GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
          )
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldConstraint.sortOrderNonNegative.constraintName}
        CHECK (
          sort_order >= 0
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldConstraint.modifiedAtAfterCreatedAt.constraintName}
        CHECK (
          modified_at >= created_at
        )
        ''',
  ];
}

enum VaultItemCustomFieldConstraint {
  idNotBlank('chk_vault_item_custom_fields_id_not_blank'),

  itemIdNotBlank('chk_vault_item_custom_fields_item_id_not_blank'),

  labelNotBlank('chk_vault_item_custom_fields_label_not_blank'),

  labelNoOuterWhitespace(
    'chk_vault_item_custom_fields_label_no_outer_whitespace',
  ),

  valueNotBlank('chk_vault_item_custom_fields_value_not_blank'),

  booleanValueFormat('chk_vault_item_custom_fields_boolean_value_format'),

  dateValueFormat('chk_vault_item_custom_fields_date_value_format'),

  sortOrderNonNegative('chk_vault_item_custom_fields_sort_order_non_negative'),

  modifiedAtAfterCreatedAt(
    'chk_vault_item_custom_fields_modified_at_after_created_at',
  );

  const VaultItemCustomFieldConstraint(this.constraintName);

  final String constraintName;
}

enum VaultItemCustomFieldIndex {
  itemId('idx_vault_item_custom_fields_item_id'),

  itemFieldType('idx_vault_item_custom_fields_item_id_field_type'),

  secretFields('idx_vault_item_custom_fields_secret_fields'),

  modifiedAt('idx_vault_item_custom_fields_modified_at');

  const VaultItemCustomFieldIndex(this.indexName);

  final String indexName;
}

final List<String> vaultItemCustomFieldsTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldIndex.itemId.indexName}
  ON vault_item_custom_fields(item_id);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldIndex.itemFieldType.indexName}
  ON vault_item_custom_fields(item_id, field_type);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldIndex.secretFields.indexName}
  ON vault_item_custom_fields(item_id, sort_order)
  WHERE is_secret = 1 OR field_type = 'concealed';
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldIndex.modifiedAt.indexName}
  ON vault_item_custom_fields(modified_at);
  ''',
];

enum VaultItemCustomFieldTrigger {
  preventCreatedAtUpdate(
    'trg_vault_item_custom_fields_prevent_created_at_update',
  );

  const VaultItemCustomFieldTrigger(this.triggerName);

  final String triggerName;
}

enum VaultItemCustomFieldRaise {
  createdAtImmutable('vault_item_custom_fields.created_at is immutable');

  const VaultItemCustomFieldRaise(this.message);

  final String message;
}

final List<String> vaultItemCustomFieldsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${VaultItemCustomFieldTrigger.preventCreatedAtUpdate.triggerName}
  BEFORE UPDATE OF created_at ON vault_item_custom_fields
  FOR EACH ROW
  WHEN NEW.created_at <> OLD.created_at
  BEGIN
    SELECT RAISE(
      ABORT,
      '${VaultItemCustomFieldRaise.createdAtImmutable.message}'
    );
  END;
  ''',
];
