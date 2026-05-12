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
  TextColumn get historyId =>
      text().references(VaultSnapshotsHistory, #id, onDelete: KeyAction.cascade)();

  /// UUID снимка для группировки связанных записей.
  TextColumn get snapshotId => text().nullable()();

  /// Quill Delta JSON snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on history policy.
  TextColumn get deltaJson => text().nullable()();

  /// Plain-text content snapshot.
  ///
  /// Nullable intentionally.
  TextColumn get content => text().nullable()();

  /// Дополнительные метаданные snapshot.
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'note_history';

  @override
  List<String> get customConstraints => [
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
  deltaJsonNotBlank('chk_note_history_delta_json_not_blank'),

  contentNotBlank('chk_note_history_content_not_blank');

  const NoteHistoryConstraint(this.constraintName);

  final String constraintName;
}
