import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

/// Type-specific таблица для заметок.
///
/// Содержит только поля, специфичные для заметки.
/// Заголовок заметки хранится в vault_items.name.
@DataClassName('NoteItemsData')
class NoteItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE.
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Quill Delta JSON представление.
  ///
  /// Храним как Text, потому что Drift/SQLite не имеют отдельного JSON-типа.
  TextColumn get deltaJson => text()();

  /// Plain-text содержимое заметки.
  ///
  /// Используется для preview, быстрого отображения и возможной индексации.
  TextColumn get content => text()();

  /// Дополнительные метаданные в JSON-формате.
  ///
  /// Например: editorVersion, contentHash, wordCount, language,
  /// pinnedRanges, formattingMigrationVersion.
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'note_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${NoteItemConstraint.deltaJsonNotBlank.constraintName}
    CHECK (
      length(trim(delta_json)) > 0
    )
    ''',

    '''
    CONSTRAINT ${NoteItemConstraint.contentNotNull.constraintName}
    CHECK (
      content IS NOT NULL
    )
    ''',
  ];
}

enum NoteItemConstraint {
  deltaJsonNotBlank(
    'chk_note_items_delta_json_not_blank',
  ),

  contentNotNull(
    'chk_note_items_content_not_null',
  );

  const NoteItemConstraint(this.constraintName);

  final String constraintName;
}