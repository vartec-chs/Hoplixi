import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'vault_items.dart';

/// Таблица связей между заметками (many-to-many).
///
/// Каждая заметка может ссылаться на множество
/// других заметок. Теперь ссылается на vault_items.id.
@DataClassName('NoteLinkData')
class NoteLinks extends Table {
  /// Уникальный идентификатор связи
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// ID исходной заметки (откуда ссылка)
  @ReferenceName('sourceNote')
  TextColumn get sourceNoteId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// ID целевой заметки (куда ссылка)
  @ReferenceName('targetNote')
  TextColumn get targetNoteId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Дата создания связи
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'note_links';

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourceNoteId, targetNoteId},
  ];
}
