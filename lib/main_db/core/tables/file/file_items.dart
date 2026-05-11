import 'package:drift/drift.dart';

import 'file_metadata.dart';
import '../vault_items/vault_items.dart';

/// Type-specific таблица для файлов.
///
/// Содержит только поля, специфичные для vault item типа "file".
/// Общие поля: name, description, categoryId, isFavorite и т.д.
/// хранятся в vault_items.
///
/// Технические свойства файла: fileName, mimeType, size, hash, path
/// хранятся в file_metadata.
@DataClassName('FileItemsData')
class FileItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE.
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Ссылка на метаданные файла.
  ///
  /// Nullable, чтобы vault item мог временно существовать без файла,
  /// например при ошибке импорта, отложенной загрузке или восстановлении.
  TextColumn get metadataId => text().nullable().references(
        FileMetadata,
        #id,
        onDelete: KeyAction.setNull,
      )();

  /// Дополнительные метаданные в JSON-формате.
  ///
  /// Например: original source, import info, user file note,
  /// attachment flags, preview settings.
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'file_items';
}

enum FileItemIndex {
  metadataId('idx_file_items_metadata_id');

  const FileItemIndex(this.indexName);

  final String indexName;
}

final List<String> fileItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${FileItemIndex.metadataId.indexName} ON file_items(metadata_id);',
];