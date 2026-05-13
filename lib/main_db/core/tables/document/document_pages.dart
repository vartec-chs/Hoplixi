import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../vault_items/vault_items.dart';
import 'document_version_pages.dart';

/// Live-указатель страницы документа.
///
/// Все восстанавливаемые данные страницы хранятся в document_version_pages.
/// Эта таблица связывает стабильный id страницы с её текущей версией.
@DataClassName('DocumentPagesData')
class DocumentPages extends Table {
  /// UUID страницы.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Документ-владелец FK -> vault_items.id.
  TextColumn get documentId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Текущая активная версия страницы.
  TextColumn get currentVersionPageId => text().nullable().references(
    DocumentVersionPages,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'document_pages';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${DocumentPageConstraint.idNotBlank.constraintName}
    CHECK (length(trim(id)) > 0)
    ''',

    '''
    CONSTRAINT ${DocumentPageConstraint.documentIdNotBlank.constraintName}
    CHECK (length(trim(document_id)) > 0)
    ''',

    '''
    CONSTRAINT ${DocumentPageConstraint.currentVersionPageIdNotBlank.constraintName}
    CHECK (
      current_version_page_id IS NULL
      OR length(trim(current_version_page_id)) > 0
    )
    ''',
  ];
}

enum DocumentPageConstraint {
  idNotBlank('chk_document_pages_id_not_blank'),

  documentIdNotBlank('chk_document_pages_document_id_not_blank'),

  currentVersionPageIdNotBlank(
    'chk_document_pages_current_version_page_id_not_blank',
  );

  const DocumentPageConstraint(this.constraintName);

  final String constraintName;
}

enum DocumentPageIndex {
  documentId('idx_document_pages_document_id'),
  currentVersionPageId('idx_document_pages_current_version_page_id'),
  uniqueDocumentCurrentVersionPage(
    'uq_document_pages_document_id_current_version_page_id',
  );

  const DocumentPageIndex(this.indexName);

  final String indexName;
}

final List<String> documentPagesTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentPageIndex.documentId.indexName} ON document_pages(document_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentPageIndex.currentVersionPageId.indexName} ON document_pages(current_version_page_id) WHERE current_version_page_id IS NOT NULL;',
  'CREATE UNIQUE INDEX IF NOT EXISTS ${DocumentPageIndex.uniqueDocumentCurrentVersionPage.indexName} ON document_pages(document_id, current_version_page_id);',
];

enum DocumentPageTrigger {
  validateDocumentTypeOnInsert('trg_document_pages_validate_document_type_on_insert'),
  validateDocumentTypeOnUpdate('trg_document_pages_validate_document_type_on_update'),
  preventDocumentIdUpdate('trg_document_pages_prevent_document_id_update'),
  validateCurrentVersionPageInsert(
    'trg_document_pages_validate_current_version_page_insert',
  ),
  validateCurrentVersionPageUpdate(
    'trg_document_pages_validate_current_version_page_update',
  );

  const DocumentPageTrigger(this.triggerName);

  final String triggerName;
}

enum DocumentPageRaise {
  invalidDocumentType(
    'document_pages.document_id must reference vault_items.id with type = document',
  ),
  documentIdImmutable('document_pages.document_id is immutable'),
  invalidCurrentVersionPage(
    'document_pages.current_version_page_id must belong to document_pages.document_id',
  );

  const DocumentPageRaise(this.message);

  final String message;
}

final List<String> documentPagesTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentPageTrigger.validateDocumentTypeOnInsert.triggerName}
  BEFORE INSERT ON document_pages
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.document_id
      AND type = 'document'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentPageRaise.invalidDocumentType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentPageTrigger.validateDocumentTypeOnUpdate.triggerName}
  BEFORE UPDATE ON document_pages
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.document_id
      AND type = 'document'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentPageRaise.invalidDocumentType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentPageTrigger.preventDocumentIdUpdate.triggerName}
  BEFORE UPDATE OF document_id ON document_pages
  FOR EACH ROW
  WHEN NEW.document_id <> OLD.document_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentPageRaise.documentIdImmutable.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentPageTrigger.validateCurrentVersionPageInsert.triggerName}
  BEFORE INSERT ON document_pages
  FOR EACH ROW
  WHEN NEW.current_version_page_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM document_version_pages dvp
      INNER JOIN document_versions dv ON dv.id = dvp.version_id
      WHERE dvp.id = NEW.current_version_page_id
        AND dv.document_id = NEW.document_id
    )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentPageRaise.invalidCurrentVersionPage.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentPageTrigger.validateCurrentVersionPageUpdate.triggerName}
  BEFORE UPDATE OF current_version_page_id ON document_pages
  FOR EACH ROW
  WHEN NEW.current_version_page_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM document_version_pages dvp
      INNER JOIN document_versions dv ON dv.id = dvp.version_id
      WHERE dvp.id = NEW.current_version_page_id
        AND dv.document_id = NEW.document_id
    )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentPageRaise.invalidCurrentVersionPage.message}'
    );
  END;
  ''',
];
