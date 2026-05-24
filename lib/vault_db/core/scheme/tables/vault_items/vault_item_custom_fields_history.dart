import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'vault_item_custom_fields.dart';
import 'vault_snapshots_history.dart';

/// History-таблица для кастомных полей vault item.
///
/// Значение value может быть NULL, если включён режим истории
/// без сохранения чувствительных/пользовательских данных.
///
/// Таблица append-only: UPDATE запрещён триггером.
@DataClassName('VaultItemCustomFieldsHistoryData')
class VaultItemCustomFieldsHistory extends Table {
  /// Уникальный идентификатор snapshot-записи кастомного поля.
  ///
  /// Не равен id оригинального custom field.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// FK → vault_snapshots_history.id ON DELETE CASCADE.
  ///
  /// Один snapshot item может иметь несколько snapshot-записей
  /// кастомных полей.
  TextColumn get snapshotHistoryId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

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

  /// Быстрый флаг секретности поля на момент snapshot.
  BoolColumn get isSecret => boolean().withDefault(const Constant(false))();

  /// Порядок отображения поля snapshot.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Дата создания исходного custom field snapshot.
  DateTimeColumn get createdAt => dateTime()();

  /// Дата последнего изменения исходного custom field snapshot.
  DateTimeColumn get modifiedAt => dateTime()();

  /// Когда создана запись истории.
  DateTimeColumn get historyCreatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'vault_item_custom_fields_history';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.idNotBlank.constraintName}
        CHECK (
          length(trim(id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.snapshotHistoryIdNotBlank.constraintName}
        CHECK (
          length(trim(snapshot_history_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.originalFieldIdNotBlank.constraintName}
        CHECK (
          original_field_id IS NULL
          OR length(trim(original_field_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.labelNotBlank.constraintName}
        CHECK (
          length(trim(label)) > 0
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.labelNoOuterWhitespace.constraintName}
        CHECK (
          label = trim(label)
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
        CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.booleanValueFormat.constraintName}
        CHECK (
          field_type != 'boolean'
          OR value IS NULL
          OR value IN ('true', 'false')
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.dateValueFormat.constraintName}
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
        CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.sortOrderNonNegative.constraintName}
        CHECK (
          sort_order >= 0
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.modifiedAtAfterCreatedAt.constraintName}
        CHECK (
          modified_at >= created_at
        )
        ''',

    '''
        CONSTRAINT ${VaultItemCustomFieldHistoryConstraint.historyCreatedAtAfterCreatedAt.constraintName}
        CHECK (
          history_created_at >= created_at
        )
        ''',
  ];
}

enum VaultItemCustomFieldHistoryConstraint {
  idNotBlank('chk_vault_item_custom_fields_history_id_not_blank'),

  snapshotHistoryIdNotBlank(
    'chk_vault_item_custom_fields_history_snapshot_history_id_not_blank',
  ),

  originalFieldIdNotBlank(
    'chk_vault_item_custom_fields_history_original_field_id_not_blank',
  ),

  labelNotBlank('chk_vault_item_custom_fields_history_label_not_blank'),

  labelNoOuterWhitespace(
    'chk_vault_item_custom_fields_history_label_no_outer_whitespace',
  ),

  valueNotBlank('chk_vault_item_custom_fields_history_value_not_blank'),

  booleanValueFormat(
    'chk_vault_item_custom_fields_history_boolean_value_format',
  ),

  dateValueFormat('chk_vault_item_custom_fields_history_date_value_format'),

  sortOrderNonNegative(
    'chk_vault_item_custom_fields_history_sort_order_non_negative',
  ),

  modifiedAtAfterCreatedAt(
    'chk_vault_item_custom_fields_history_modified_at_after_created_at',
  ),

  historyCreatedAtAfterCreatedAt(
    'chk_vault_item_custom_fields_history_history_created_at_after_created_at',
  );

  const VaultItemCustomFieldHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum VaultItemCustomFieldHistoryIndex {
  snapshotHistoryId('idx_vault_item_custom_fields_history_snapshot_history_id'),

  originalFieldId('idx_vault_item_custom_fields_history_original_field_id'),

  snapshotHistoryFieldType(
    'idx_vault_item_custom_fields_history_snapshot_history_id_field_type',
  ),

  secretFields('idx_vault_item_custom_fields_history_secret_fields'),

  historyCreatedAt('idx_vault_item_custom_fields_history_history_created_at');

  const VaultItemCustomFieldHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> vaultItemCustomFieldsHistoryTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldHistoryIndex.snapshotHistoryId.indexName}
  ON vault_item_custom_fields_history(snapshot_history_id);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldHistoryIndex.originalFieldId.indexName}
  ON vault_item_custom_fields_history(original_field_id)
  WHERE original_field_id IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldHistoryIndex.snapshotHistoryFieldType.indexName}
  ON vault_item_custom_fields_history(snapshot_history_id, field_type);
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldHistoryIndex.secretFields.indexName}
  ON vault_item_custom_fields_history(snapshot_history_id, sort_order)
  WHERE is_secret = 1 OR field_type = 'concealed';
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${VaultItemCustomFieldHistoryIndex.historyCreatedAt.indexName}
  ON vault_item_custom_fields_history(history_created_at DESC);
  ''',
];

enum VaultItemCustomFieldHistoryTrigger {
  preventUpdate('trg_vault_item_custom_fields_history_prevent_update');

  const VaultItemCustomFieldHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum VaultItemCustomFieldHistoryRaise {
  historyIsImmutable('vault_item_custom_fields_history rows are immutable');

  const VaultItemCustomFieldHistoryRaise(this.message);

  final String message;
}

final List<String> vaultItemCustomFieldsHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${VaultItemCustomFieldHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON vault_item_custom_fields_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${VaultItemCustomFieldHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
