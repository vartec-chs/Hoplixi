import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';

/// History-таблица для специфичных полей recovery codes.
///
/// Данные вставляются только триггерами.
/// Сами коды обычно хранятся в отдельной таблице `recovery_codes`.
@DataClassName('RecoveryCodesHistoryData')
class RecoveryCodesHistory extends Table {
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Snapshot общего количества кодов.
  IntColumn get codesCount => integer().withDefault(const Constant(0))();

  /// Snapshot количества использованных кодов.
  IntColumn get usedCount => integer().withDefault(const Constant(0))();

  /// Snapshot даты генерации набора recovery codes.
  DateTimeColumn get generatedAt => dateTime().nullable()();

  /// Snapshot признака одноразового набора.
  BoolColumn get oneTime => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'recovery_codes_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${RecoveryCodesHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (length(trim(history_id)) > 0)
    ''',
    '''
    CONSTRAINT ${RecoveryCodesHistoryConstraint.codesCountNonNegative.constraintName}
    CHECK (
      codes_count >= 0
    )
    ''',
    '''
    CONSTRAINT ${RecoveryCodesHistoryConstraint.usedCountNonNegative.constraintName}
    CHECK (
      used_count >= 0
    )
    ''',
    '''
    CONSTRAINT ${RecoveryCodesHistoryConstraint.usedCountNotGreaterThanCodesCount.constraintName}
    CHECK (
      used_count <= codes_count
    )
    ''',
  ];
}

enum RecoveryCodesHistoryConstraint {
  historyIdNotBlank('chk_recovery_codes_history_history_id_not_blank'),

  codesCountNonNegative('chk_recovery_codes_history_codes_count_non_negative'),

  usedCountNonNegative('chk_recovery_codes_history_used_count_non_negative'),

  usedCountNotGreaterThanCodesCount(
    'chk_recovery_codes_history_used_count_not_greater_than_codes_count',
  );

  const RecoveryCodesHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum RecoveryCodesHistoryIndex {
  generatedAt('idx_recovery_codes_history_generated_at');

  const RecoveryCodesHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> recoveryCodesHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${RecoveryCodesHistoryIndex.generatedAt.indexName} ON recovery_codes_history(generated_at) WHERE generated_at IS NOT NULL;',
];

enum RecoveryCodesHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_recovery_codes_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_recovery_codes_history_prevent_update');

  const RecoveryCodesHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum RecoveryCodesHistoryRaise {
  invalidSnapshotType(
    'recovery_codes_history.history_id must reference vault_snapshots_history.id with type = recoveryCodes',
  ),

  historyIsImmutable('recovery_codes_history rows are immutable');

  const RecoveryCodesHistoryRaise(this.message);

  final String message;
}

final List<String> recoveryCodesHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${RecoveryCodesHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON recovery_codes_history
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
      '${RecoveryCodesHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${RecoveryCodesHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON recovery_codes_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${RecoveryCodesHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
