import 'package:drift/drift.dart';

import 'tags.dart';
import '../vault_items/vault_items.dart';

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
}

enum ItemTagIndex {
  itemId('idx_item_tags_item_id'),
  tagId('idx_item_tags_tag_id'),
  createdAt('idx_item_tags_created_at');

  const ItemTagIndex(this.indexName);

  final String indexName;
}

final List<String> itemTagsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${ItemTagIndex.itemId.indexName} ON item_tags(item_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemTagIndex.tagId.indexName} ON item_tags(tag_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemTagIndex.createdAt.indexName} ON item_tags(created_at);',
];
