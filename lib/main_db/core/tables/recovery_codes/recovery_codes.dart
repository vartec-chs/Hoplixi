import 'package:drift/drift.dart';

import 'recovery_codes_items.dart';

@DataClassName('RecoveryCodeData')
class RecoveryCodes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get itemId => text().references(
    RecoveryCodesItems,
    #itemId,
    onDelete: KeyAction.cascade,
  )();

  /// Recovery code.
  ///
  /// Secret!!!. Не ограничиваем длину:
  /// у разных сервисов форматы recovery codes отличаются.
  TextColumn get code => text()();

  /// Использован ли код.
  BoolColumn get used => boolean().withDefault(const Constant(false))();

  /// Дата использования.
  DateTimeColumn get usedAt => dateTime().nullable()();

  /// Позиция кода в исходном списке.
  IntColumn get position => integer().nullable()();

  @override
  String get tableName => 'recovery_codes';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${RecoveryCodeConstraint.itemIdNotBlank.constraintName}
    CHECK (length(trim(item_id)) > 0)
    ''',

    '''
    CONSTRAINT ${RecoveryCodeConstraint.codeNotBlank.constraintName}
    CHECK (
      length(trim(code)) > 0
    )
    ''',

    '''
    CONSTRAINT ${RecoveryCodeConstraint.usedAtConsistency.constraintName}
    CHECK (
      (used = 1 AND used_at IS NOT NULL)
      OR
      (used = 0 AND used_at IS NULL)
    )
    ''',

    '''
    CONSTRAINT ${RecoveryCodeConstraint.positionNonNegative.constraintName}
    CHECK (
      position IS NULL
      OR position >= 0
    )
    ''',

    '''
    CONSTRAINT ${RecoveryCodeConstraint.uniqueItemPosition.constraintName}
    UNIQUE (item_id, position)
    ''',
  ];
}

enum RecoveryCodeConstraint {
  itemIdNotBlank('chk_recovery_codes_item_id_not_blank'),

  codeNotBlank('chk_recovery_codes_code_not_blank'),

  usedAtConsistency('chk_recovery_codes_used_at_consistency'),

  positionNonNegative('chk_recovery_codes_position_non_negative'),

  uniqueItemPosition('chk_recovery_codes_unique_item_position');

  const RecoveryCodeConstraint(this.constraintName);

  final String constraintName;
}

enum RecoveryCodeIndex {
  itemId('idx_recovery_codes_item_id'),
  itemUsed('idx_recovery_codes_item_id_used'),
  usedAt('idx_recovery_codes_used_at'),
  itemPosition('idx_recovery_codes_item_id_position');

  const RecoveryCodeIndex(this.indexName);

  final String indexName;
}

final List<String> recoveryCodesTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodeIndex.itemId.indexName} ON recovery_codes(item_id);',
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodeIndex.itemUsed.indexName} ON recovery_codes(item_id, used);',
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodeIndex.usedAt.indexName} ON recovery_codes(used_at) WHERE used_at IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodeIndex.itemPosition.indexName} ON recovery_codes(item_id, position) WHERE position IS NOT NULL;',
];

enum RecoveryCodeTrigger {
  afterInsertRecalculateCounts('trg_recovery_codes_after_insert_recalculate'),
  afterUpdateRecalculateCounts('trg_recovery_codes_after_update_recalculate'),
  afterDeleteRecalculateCounts('trg_recovery_codes_after_delete_recalculate'),
  preventItemIdUpdate('trg_recovery_codes_prevent_item_id_update');

  const RecoveryCodeTrigger(this.triggerName);

  final String triggerName;
}

enum RecoveryCodeRaise {
  itemIdImmutable('recovery_codes.item_id is immutable');

  const RecoveryCodeRaise(this.message);

  final String message;
}

final List<String> recoveryCodesTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${RecoveryCodeTrigger.afterInsertRecalculateCounts.triggerName}
  AFTER INSERT ON recovery_codes
  BEGIN
    UPDATE recovery_codes_items
    SET codes_count = (SELECT COUNT(*) FROM recovery_codes WHERE item_id = NEW.item_id),
        used_count = (SELECT COUNT(*) FROM recovery_codes WHERE item_id = NEW.item_id AND used = 1)
    WHERE item_id = NEW.item_id;
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${RecoveryCodeTrigger.afterUpdateRecalculateCounts.triggerName}
  AFTER UPDATE OF used, item_id ON recovery_codes
  BEGIN
    -- Update counts for the new item_id (or same if item_id didn't change)
    UPDATE recovery_codes_items
    SET codes_count = (SELECT COUNT(*) FROM recovery_codes WHERE item_id = NEW.item_id),
        used_count = (SELECT COUNT(*) FROM recovery_codes WHERE item_id = NEW.item_id AND used = 1)
    WHERE item_id = NEW.item_id;

    -- If item_id changed (though preventItemIdUpdate should catch it), update the old one too
    UPDATE recovery_codes_items
    SET codes_count = (SELECT COUNT(*) FROM recovery_codes WHERE item_id = OLD.item_id),
        used_count = (SELECT COUNT(*) FROM recovery_codes WHERE item_id = OLD.item_id AND used = 1)
    WHERE item_id = OLD.item_id AND OLD.item_id <> NEW.item_id;
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${RecoveryCodeTrigger.afterDeleteRecalculateCounts.triggerName}
  AFTER DELETE ON recovery_codes
  BEGIN
    UPDATE recovery_codes_items
    SET codes_count = (SELECT COUNT(*) FROM recovery_codes WHERE item_id = OLD.item_id),
        used_count = (SELECT COUNT(*) FROM recovery_codes WHERE item_id = OLD.item_id AND used = 1)
    WHERE item_id = OLD.item_id;
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${RecoveryCodeTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON recovery_codes
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${RecoveryCodeRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
