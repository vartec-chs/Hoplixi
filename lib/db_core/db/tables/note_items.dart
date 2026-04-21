import 'package:drift/drift.dart';

import 'vault_items.dart';

/// Type-specific таблица для заметок.
///
/// Содержит ТОЛЬКО поля, специфичные для заметки.
/// Заголовок заметки хранится в vault_items.name.
@DataClassName('NoteItemsData')
class NoteItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Quill Delta JSON представление
  TextColumn get deltaJson => text()();

  /// Текстовое содержимое заметки
  TextColumn get content => text()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'note_items';
}
