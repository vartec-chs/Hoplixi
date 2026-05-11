import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'vault_item_custom_fields.dart';
import 'vault_item_history.dart';

/// History-таблица для кастомных полей vault item.
///
/// Данные вставляются только триггерами.
/// Значение value может быть NULL, если включён режим истории
/// без сохранения чувствительных/пользовательских данных.
@DataClassName('VaultItemCustomFieldsHistoryData')
class VaultItemCustomFieldsHistory extends Table {
  /// Уникальный идентификатор snapshot-записи кастомного поля.
  ///
  /// Не равен id оригинального custom field.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// FK → vault_item_history.id ON DELETE CASCADE.
  ///
  /// Одна запись истории vault item может иметь несколько snapshot
  /// кастомных полей.
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// ID исходного custom field.
  ///
  /// Не FK специально: оригинальное поле может быть удалено,
  /// а history должна сохранить snapshot.
  TextColumn get originalFieldId => text().nullable()();

  /// Отображаемое название поля snapshot.
  TextColumn get label => text().withLength(min: 1, max: 255)();

  /// Значение поля snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on history policy.
  TextColumn get value => text().nullable()();

  /// Тип поля snapshot.
  TextColumn get fieldType =>
      textEnum<CustomFieldType>().withDefault(const Constant('text'))();

  /// Дополнительный тип поля, если fieldType = other.
  TextColumn get fieldTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Порядок отображения поля snapshot.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_item_custom_fields_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.labelNotBlank.constraintName}
    CHECK (
      length(trim(label)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.valueNotBlank.constraintName}
    CHECK (
      value IS NULL
      OR length(trim(value)) > 0
    )
    ''',

    '''
    CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.fieldTypeOtherRequired.constraintName}
    CHECK (
      field_type != 'other'
      OR (
        field_type_other IS NOT NULL
        AND length(trim(field_type_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.fieldTypeOtherMustBeNull.constraintName}
    CHECK (
      field_type = 'other'
      OR field_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.sortOrderNonNegative.constraintName}
    CHECK (
      sort_order >= 0
    )
    ''',
  ];
}

enum VaultItemCustomFieldHistoryConstraint {
  labelNotBlank('chk_vault_item_custom_fields_history_label_not_blank'),

  valueNotBlank('chk_vault_item_custom_fields_history_value_not_blank'),

  fieldTypeOtherRequired(
    'chk_vault_item_custom_fields_history_field_type_other_required',
  ),

  fieldTypeOtherMustBeNull(
    'chk_vault_item_custom_fields_history_field_type_other_must_be_null',
  ),

  sortOrderNonNegative(
    'chk_vault_item_custom_fields_history_sort_order_non_negative',
  );

  const VaultItemCustomFieldHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum VaultItemCustomFieldHistoryIndex {
  historyId('idx_vault_item_custom_fields_history_history_id'),
  originalFieldId('idx_vault_item_custom_fields_history_original_field_id'),
  fieldType('idx_vault_item_custom_fields_history_field_type'),
  sortOrder('idx_vault_item_custom_fields_history_sort_order'),
  historySortOrder(
    'idx_vault_item_custom_fields_history_history_id_sort_order',
  );

  const VaultItemCustomFieldHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> vaultItemCustomFieldsHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldHistoryIndex.historyId.indexName} ON vault_item_custom_fields_history(history_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldHistoryIndex.originalFieldId.indexName} ON vault_item_custom_fields_history(original_field_id);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldHistoryIndex.fieldType.indexName} ON vault_item_custom_fields_history(field_type);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldHistoryIndex.sortOrder.indexName} ON vault_item_custom_fields_history(sort_order);',
  'CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldHistoryIndex.historySortOrder.indexName} ON vault_item_custom_fields_history(history_id, sort_order);',
];
