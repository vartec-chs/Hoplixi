import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';
import 'file_metadata.dart';

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

enum FileItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_file_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_file_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_file_items_prevent_item_id_update');

  const FileItemTrigger(this.triggerName);

  final String triggerName;
}

enum FileItemRaise {
  invalidVaultItemType(
    'file_items.item_id must reference vault_items.id with type = file',
  ),

  itemIdImmutable('file_items.item_id is immutable');

  const FileItemRaise(this.message);

  final String message;
}

final List<String> fileItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${FileItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON file_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'file'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${FileItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${FileItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON file_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'file'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${FileItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${FileItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON file_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${FileItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
