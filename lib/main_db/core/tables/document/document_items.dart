import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';
import 'document_versions.dart';

export 'document_types.dart';

/// Type-specific таблица для документов.
///
/// Все восстанавливаемые данные документа хранятся в document_versions.
/// Здесь остаётся только ссылка на текущую версию.
@DataClassName('DocumentItemsData')
class DocumentItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE.
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Текущая активная версия документа.
  TextColumn get currentVersionId => text().nullable().references(
    DocumentVersions,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'document_items';
}

enum DocumentItemIndex {
  currentVersionId('idx_document_items_current_version_id');

  const DocumentItemIndex(this.indexName);

  final String indexName;
}

final List<String> documentItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentItemIndex.currentVersionId.indexName} ON document_items(current_version_id);',
];

enum DocumentItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_document_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_document_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_document_items_prevent_item_id_update');

  const DocumentItemTrigger(this.triggerName);

  final String triggerName;
}

enum DocumentItemRaise {
  invalidVaultItemType(
    'document_items.item_id must reference vault_items.id with type = document',
  ),

  itemIdImmutable('document_items.item_id is immutable');

  const DocumentItemRaise(this.message);

  final String message;
}

final List<String> documentItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON document_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'document'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON document_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'document'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON document_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
