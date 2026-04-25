import 'package:drift/drift.dart';

import 'file_metadata.dart';
import 'vault_items.dart';

/// Type-specific таблица для файлов.
///
/// Содержит ТОЛЬКО поля, специфичные для файла.
/// Общие поля (name, categoryId, isFavorite и т.д.)
/// хранятся в vault_items.
@DataClassName('FileItemsData')
class FileItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Ссылка на метаданные файла
  TextColumn get metadataId => text().nullable().references(
    FileMetadata,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'file_items';
}
