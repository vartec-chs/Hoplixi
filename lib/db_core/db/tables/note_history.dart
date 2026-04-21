import 'package:drift/drift.dart';

import 'vault_item_history.dart';

/// History-таблица для специфичных полей заметки.
@DataClassName('NoteHistoryData')
class NoteHistory extends Table {
  /// PK и FK → vault_item_history.id ON DELETE CASCADE
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Quill Delta JSON (snapshot)
  TextColumn get deltaJson => text()();

  /// Текстовое содержимое (snapshot)
  TextColumn get content => text()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'note_history';
}
