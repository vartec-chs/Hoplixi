import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'vault_items.dart';

/// Таблица связей note -> vault item.
///
/// Источник связи всегда заметка, а целевая запись может быть
/// любым `vault_items` элементом.
@DataClassName('NoteLinkData')
class NoteLinks extends Table {
  /// Уникальный идентификатор связи
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// ID исходной заметки (откуда ссылка)
  @ReferenceName('sourceNote')
  TextColumn get sourceNoteId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// ID целевого vault item (куда ссылка)
  @ReferenceName('targetVaultItem')
  TextColumn get targetVaultItemId =>
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
    {sourceNoteId, targetVaultItemId},
  ];
}
