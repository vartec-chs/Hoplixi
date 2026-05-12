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
  List<Set<Column>> get uniqueKeys => [
    {documentId, currentVersionPageId},
  ];

  @override
  String get tableName => 'document_pages';
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
  'CREATE INDEX IF NOT EXISTS ${DocumentPageIndex.currentVersionPageId.indexName} ON document_pages(current_version_page_id);',
  'CREATE UNIQUE INDEX IF NOT EXISTS ${DocumentPageIndex.uniqueDocumentCurrentVersionPage.indexName} ON document_pages(document_id, current_version_page_id);',
];

enum DocumentPageTrigger {
  validateCurrentVersionPageInsert(
    'document_pages_validate_current_version_page_insert',
  ),
  validateCurrentVersionPageUpdate(
    'document_pages_validate_current_version_page_update',
  );

  const DocumentPageTrigger(this.triggerName);

  final String triggerName;
}

const List<String> documentPagesTableTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS document_pages_validate_current_version_page_insert
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
        'document_pages.current_version_page_id must belong to document_pages.document_id'
      );
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS document_pages_validate_current_version_page_update
    BEFORE UPDATE OF document_id, current_version_page_id ON document_pages
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
        'document_pages.current_version_page_id must belong to document_pages.document_id'
      );
    END;
  ''',
];

final List<String> documentPagesTableDropTriggers = [
  'DROP TRIGGER IF EXISTS ${DocumentPageTrigger.validateCurrentVersionPageInsert.triggerName};',
  'DROP TRIGGER IF EXISTS ${DocumentPageTrigger.validateCurrentVersionPageUpdate.triggerName};',
];
