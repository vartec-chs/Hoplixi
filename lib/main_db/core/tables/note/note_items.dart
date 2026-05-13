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
  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'note_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${NoteItemConstraint.itemIdNotBlank.constraintName}
    CHECK (length(trim(item_id)) > 0)
    ''',

    '''
    CONSTRAINT ${NoteItemConstraint.deltaJsonNotBlank.constraintName}
    CHECK (
      length(trim(delta_json)) > 0
    )
    ''',

    '''
    CONSTRAINT ${NoteItemConstraint.contentNotBlank.constraintName}
    CHECK (
      length(trim(content)) > 0
    )
    ''',
  ];
}

enum NoteItemConstraint {
  itemIdNotBlank('chk_note_items_item_id_not_blank'),

  deltaJsonNotBlank('chk_note_items_delta_json_not_blank'),

  contentNotBlank('chk_note_items_content_not_blank');

  const NoteItemConstraint(this.constraintName);

  final String constraintName;
}

enum NoteItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_note_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_note_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_note_items_prevent_item_id_update');

  const NoteItemTrigger(this.triggerName);

  final String triggerName;
}

enum NoteItemRaise {
  invalidVaultItemType(
    'note_items.item_id must reference vault_items.id with type = note',
  ),

  itemIdImmutable('note_items.item_id is immutable');

  const NoteItemRaise(this.message);

  final String message;
}

final List<String> noteItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${NoteItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON note_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'note'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${NoteItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${NoteItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON note_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'note'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${NoteItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${NoteItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON note_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${NoteItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
