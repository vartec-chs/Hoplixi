import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart';

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
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${DocumentItemConstraint.itemIdNotBlank.constraintName}
    CHECK (length(trim(item_id)) > 0)
    ''',

    '''
    CONSTRAINT ${DocumentItemConstraint.currentVersionIdNotBlank.constraintName}
    CHECK (
      current_version_id IS NULL
      OR length(trim(current_version_id)) > 0
    )
    ''',
  ];
}

@JsonEnum(fieldRename: FieldRename.snake)
enum DocumentItemConstraint {
  itemIdNotBlank('chk_document_items_item_id_not_blank'),

  currentVersionIdNotBlank('chk_document_items_current_version_id_not_blank');

  const DocumentItemConstraint(this.constraintName);

  final String constraintName;
}

@JsonEnum(fieldRename: FieldRename.snake)
enum DocumentItemIndex {
  currentVersionId('idx_document_items_current_version_id');

  const DocumentItemIndex(this.indexName);

  final String indexName;
}

final List<String> documentItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentItemIndex.currentVersionId.indexName} ON document_items(current_version_id) WHERE current_version_id IS NOT NULL;',
];

@JsonEnum(fieldRename: FieldRename.snake)
enum DocumentItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_document_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_document_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_document_items_prevent_item_id_update'),

  validateCurrentVersionOnInsert(
    'trg_document_items_validate_current_version_on_insert',
  ),

  validateCurrentVersionOnUpdate(
    'trg_document_items_validate_current_version_on_update',
  );

  const DocumentItemTrigger(this.triggerName);

  final String triggerName;
}

@JsonEnum(fieldRename: FieldRename.snake)
enum DocumentItemRaise {
  invalidVaultItemType(
    'document_items.item_id must reference vault_items.id with type = document',
  ),

  itemIdImmutable('document_items.item_id is immutable'),

  invalidCurrentVersion(
    'document_items.current_version_id must belong to this document',
  );

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

  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentItemTrigger.validateCurrentVersionOnInsert.triggerName}
  BEFORE INSERT ON document_items
  FOR EACH ROW
  WHEN NEW.current_version_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM document_versions
      WHERE id = NEW.current_version_id
        AND document_id = NEW.item_id
    )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentItemRaise.invalidCurrentVersion.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentItemTrigger.validateCurrentVersionOnUpdate.triggerName}
  BEFORE UPDATE OF current_version_id ON document_items
  FOR EACH ROW
  WHEN NEW.current_version_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM document_versions
      WHERE id = NEW.current_version_id
        AND document_id = NEW.item_id
    )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentItemRaise.invalidCurrentVersion.message}'
    );
  END;
  ''',
];
