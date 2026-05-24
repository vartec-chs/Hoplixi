import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';
import 'tags.dart';

/// Единая таблица связи элементов хранилища и тегов.
///
/// Заменяет отдельные таблицы password_tags, note_tags,
/// otp_tags, bank_cards_tags, files_tags, documents_tags.
@DataClassName('ItemTagsData')
class ItemTags extends Table {
  /// FK → vault_items.id ON DELETE CASCADE.
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// FK → tags.id ON DELETE CASCADE.
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  /// Дата создания связи.
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {itemId, tagId};

  @override
  String get tableName => 'item_tags';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${ItemTagsConstraint.itemIdNotBlank.constraintName}
    CHECK (
      length(trim(item_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ItemTagsConstraint.tagIdNotBlank.constraintName}
    CHECK (
      length(trim(tag_id)) > 0
    )
    ''',
  ];
}

enum ItemTagsConstraint {
  itemIdNotBlank('chk_item_tags_item_id_not_blank'),

  tagIdNotBlank('chk_item_tags_tag_id_not_blank');

  const ItemTagsConstraint(this.constraintName);

  final String constraintName;
}

enum ItemTagsTrigger {
  preventCreatedAtUpdate('trg_item_tags_prevent_created_at_update');

  const ItemTagsTrigger(this.triggerName);

  final String triggerName;
}

enum ItemTagsRaise {
  createdAtImmutable('item_tags.created_at is immutable');

  const ItemTagsRaise(this.message);

  final String message;
}

final List<String> itemTagsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${ItemTagIndex.itemId.indexName} ON item_tags(item_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemTagIndex.tagId.indexName} ON item_tags(tag_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemTagIndex.createdAt.indexName} ON item_tags(created_at);',
];

final List<String> itemTagsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemTagsTrigger.preventCreatedAtUpdate.triggerName}
  BEFORE UPDATE OF created_at ON item_tags
  FOR EACH ROW
  WHEN NEW.created_at <> OLD.created_at
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ItemTagsRaise.createdAtImmutable.message}'
    );
  END;
  ''',
];

enum ItemTagIndex {
  itemId('idx_item_tags_item_id'),
  tagId('idx_item_tags_tag_id'),
  createdAt('idx_item_tags_created_at');

  const ItemTagIndex(this.indexName);

  final String indexName;
}
