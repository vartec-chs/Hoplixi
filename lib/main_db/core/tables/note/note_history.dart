import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';

/// History-таблица для специфичных полей заметки.
///
/// Данные вставляются только триггерами.
/// Содержимое заметки может быть NULL, если включён режим истории
/// без сохранения чувствительных данных.
@DataClassName('NoteHistoryData')
class NoteHistory extends Table {
  /// PK и FK → vault_snapshots_history.id ON DELETE CASCADE.
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Quill Delta JSON snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on history policy.
  TextColumn get deltaJson => text().nullable()();

  /// Plain-text content snapshot.
  ///
  /// Nullable intentionally.
  TextColumn get content => text().nullable()();
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'note_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${NoteHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (length(trim(history_id)) > 0)
    ''',

    '''
    CONSTRAINT ${NoteHistoryConstraint.deltaJsonNotBlank.constraintName}
    CHECK (
      delta_json IS NULL
      OR length(trim(delta_json)) > 0
    )
    ''',

    '''
    CONSTRAINT ${NoteHistoryConstraint.contentNotBlank.constraintName}
    CHECK (
      content IS NULL
      OR length(trim(content)) > 0
    )
    ''',
  ];
}

enum NoteHistoryConstraint {
  historyIdNotBlank('chk_note_history_history_id_not_blank'),

  deltaJsonNotBlank('chk_note_history_delta_json_not_blank'),

  contentNotBlank('chk_note_history_content_not_blank');

  const NoteHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum NoteHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_note_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_note_history_prevent_update');

  const NoteHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum NoteHistoryRaise {
  invalidSnapshotType(
    'note_history.history_id must reference vault_snapshots_history.id with type = note',
  ),

  historyIsImmutable('note_history rows are immutable');

  const NoteHistoryRaise(this.message);

  final String message;
}

final List<String> noteHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${NoteHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON note_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'note'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${NoteHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${NoteHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON note_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${NoteHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
