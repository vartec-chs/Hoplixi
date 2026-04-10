import 'package:drift/drift.dart';

import 'tags.dart';
import 'vault_items.dart';

/// Единая таблица связи элементов хранилища и тегов.
///
/// Заменяет отдельные таблицы password_tags, note_tags,
/// otp_tags, bank_cards_tags, files_tags, documents_tags.
@DataClassName('ItemTagsData')
class ItemTags extends Table {
  /// FK → vault_items.id ON DELETE CASCADE
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// FK → tags.id ON DELETE CASCADE
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  /// Дата создания связи
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {itemId, tagId};

  @override
  String get tableName => 'item_tags';
}
