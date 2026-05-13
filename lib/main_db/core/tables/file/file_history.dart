import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';
import 'file_metadata_history.dart';

/// History-таблица для специфичных полей файла.
///
/// Данные вставляются только триггерами.
@DataClassName('FileHistoryData')
class FileHistory extends Table {
  /// PK и FK → vault_snapshots_history.id ON DELETE CASCADE.
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Ссылка на snapshot file_metadata_history.
  ///
  /// FK можно ставить, потому что это ссылка не на live file_metadata,
  /// а на immutable history snapshot.
  TextColumn get metadataHistoryId => text().nullable().references(
    FileMetadataHistory,
    #id,
    onDelete: KeyAction.setNull,
  )();
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'file_history';
}

enum FileHistoryIndex {
  metadataHistoryId('idx_file_history_metadata_history_id');

  const FileHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> fileHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${FileHistoryIndex.metadataHistoryId.indexName} ON file_history(metadata_history_id);',
];

enum FileHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_file_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_file_history_prevent_update');

  const FileHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum FileHistoryRaise {
  invalidSnapshotType(
    'file_history.history_id must reference vault_snapshots_history.id with type = file',
  ),

  historyIsImmutable('file_history rows are immutable');

  const FileHistoryRaise(this.message);

  final String message;
}

final List<String> fileHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${FileHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON file_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'file'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${FileHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${FileHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON file_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${FileHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
