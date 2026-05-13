import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

@DataClassName('RecoveryCodesItemsData')
class RecoveryCodesItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Кэш: общее количество кодов.
  ///
  /// Обновляется триггерами при изменении recovery_codes.
  IntColumn get codesCount => integer().withDefault(const Constant(0))();

  /// Кэш: количество использованных кодов.
  ///
  /// Обновляется триггерами при изменении recovery_codes.
  IntColumn get usedCount => integer().withDefault(const Constant(0))();

  /// Дата генерации набора recovery codes.
  DateTimeColumn get generatedAt => dateTime().nullable()();

  /// Набор одноразовых кодов.
  BoolColumn get oneTime => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'recovery_codes_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${RecoveryCodesItemConstraint.codesCountNonNegative.constraintName}
    CHECK (
      codes_count >= 0
    )
    ''',
    '''
    CONSTRAINT ${RecoveryCodesItemConstraint.usedCountNonNegative.constraintName}
    CHECK (
      used_count >= 0
    )
    ''',
    '''
    CONSTRAINT ${RecoveryCodesItemConstraint.usedCountNotGreaterThanCodesCount.constraintName}
    CHECK (
      used_count <= codes_count
    )
    ''',
  ];
}

enum RecoveryCodesItemConstraint {
  codesCountNonNegative('chk_recovery_codes_items_codes_count_non_negative'),

  usedCountNonNegative('chk_recovery_codes_items_used_count_non_negative'),

  usedCountNotGreaterThanCodesCount(
    'chk_recovery_codes_items_used_count_not_greater_than_codes_count',
  );

  const RecoveryCodesItemConstraint(this.constraintName);

  final String constraintName;
}

enum RecoveryCodesItemIndex {
  generatedAt('idx_recovery_codes_items_generated_at');

  const RecoveryCodesItemIndex(this.indexName);

  final String indexName;
}

final List<String> recoveryCodesItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodesItemIndex.generatedAt.indexName} ON recovery_codes_items(generated_at);',
];

enum RecoveryCodesItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_recovery_codes_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_recovery_codes_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_recovery_codes_items_prevent_item_id_update');

  const RecoveryCodesItemTrigger(this.triggerName);

  final String triggerName;
}

enum RecoveryCodesItemRaise {
  invalidVaultItemType(
    'recovery_codes_items.item_id must reference vault_items.id with type = recoveryCodes',
  ),

  itemIdImmutable('recovery_codes_items.item_id is immutable');

  const RecoveryCodesItemRaise(this.message);

  final String message;
}

final List<String> recoveryCodesItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${RecoveryCodesItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON recovery_codes_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'recoveryCodes'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${RecoveryCodesItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${RecoveryCodesItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON recovery_codes_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'recoveryCodes'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${RecoveryCodesItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${RecoveryCodesItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON recovery_codes_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${RecoveryCodesItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
