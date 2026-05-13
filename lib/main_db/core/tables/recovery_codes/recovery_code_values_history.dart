import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';

/// Snapshot отдельных recovery codes.
///
/// Используется для полного восстановления набора кодов из истории.
@DataClassName('RecoveryCodeValuesHistoryData')
class RecoveryCodeValuesHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// FK к истории vault item.
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// ID оригинальной записи recovery_codes на момент создания snapshot.
  IntColumn get originalCodeId => integer().nullable()();

  /// Snapshot значения кода.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on history policy.
  TextColumn get code => text().nullable()();

  /// Snapshot статуса использования.
  BoolColumn get used => boolean().withDefault(const Constant(false))();

  /// Snapshot даты использования.
  DateTimeColumn get usedAt => dateTime().nullable()();

  /// Snapshot позиции кода.
  IntColumn get position => integer().nullable()();

  @override
  String get tableName => 'recovery_code_values_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${RecoveryCodeValuesHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (length(trim(history_id)) > 0)
    ''',

    '''
    CONSTRAINT ${RecoveryCodeValuesHistoryConstraint.codeNotBlank.constraintName}
    CHECK (
      code IS NULL
      OR length(trim(code)) > 0
    )
    ''',

    '''
    CONSTRAINT ${RecoveryCodeValuesHistoryConstraint.usedAtConsistency.constraintName}
    CHECK (
      (used = 1 AND used_at IS NOT NULL)
      OR
      (used = 0 AND used_at IS NULL)
    )
    ''',

    '''
    CONSTRAINT ${RecoveryCodeValuesHistoryConstraint.positionNonNegative.constraintName}
    CHECK (
      position IS NULL
      OR position >= 0
    )
    ''',

    '''
    CONSTRAINT ${RecoveryCodeValuesHistoryConstraint.uniqueHistoryPosition.constraintName}
    UNIQUE (history_id, position)
    ''',
  ];
}

enum RecoveryCodeValuesHistoryConstraint {
  historyIdNotBlank('chk_recovery_code_values_history_history_id_not_blank'),

  codeNotBlank('chk_recovery_code_values_history_code_not_blank'),

  usedAtConsistency('chk_recovery_code_values_history_used_at_consistency'),

  positionNonNegative('chk_recovery_code_values_history_position_non_negative'),

  uniqueHistoryPosition('chk_recovery_code_values_history_unique_history_position');

  const RecoveryCodeValuesHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum RecoveryCodeValuesHistoryIndex {
  historyId('idx_recovery_code_values_history_history_id'),
  historyPosition('idx_recovery_code_values_history_history_id_position'),
  historyUsed('idx_recovery_code_values_history_history_id_used');

  const RecoveryCodeValuesHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> recoveryCodeValuesHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodeValuesHistoryIndex.historyId.indexName} ON recovery_code_values_history(history_id);',
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodeValuesHistoryIndex.historyPosition.indexName} ON recovery_code_values_history(history_id, position) WHERE position IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodeValuesHistoryIndex.historyUsed.indexName} ON recovery_code_values_history(history_id, used);',
];

enum RecoveryCodeValuesHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_recovery_code_values_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_recovery_code_values_history_prevent_update');

  const RecoveryCodeValuesHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum RecoveryCodeValuesHistoryRaise {
  invalidSnapshotType(
    'recovery_code_values_history.history_id must reference vault_snapshots_history.id with type = recoveryCodes',
  ),

  historyIsImmutable('recovery_code_values_history rows are immutable');

  const RecoveryCodeValuesHistoryRaise(this.message);

  final String message;
}

final List<String> recoveryCodeValuesHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${RecoveryCodeValuesHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON recovery_code_values_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'recoveryCodes'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${RecoveryCodeValuesHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${RecoveryCodeValuesHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON recovery_code_values_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${RecoveryCodeValuesHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
