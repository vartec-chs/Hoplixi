import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import '../file/file_metadata_history.dart';
import '../vault_items/vault_items.dart';
import 'document_versions.dart';

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

/// Страницы конкретной версии документа.
@DataClassName('DocumentVersionPagesData')
class DocumentVersionPages extends Table {
  /// UUID страницы версии.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Версия документа FK -> document_versions.id.
  TextColumn get versionId =>
      text().references(DocumentVersions, #id, onDelete: KeyAction.cascade)();

  /// Стабильная live-страница документа, которой принадлежит эта version-page.
  TextColumn get pageId =>
      text().references(DocumentPages, #id, onDelete: KeyAction.cascade)();

  /// Snapshot метаданных файла страницы.
  TextColumn get metadataHistoryId => text().nullable().references(
    FileMetadataHistory,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Порядковый номер страницы в версии, начиная с 1.
  IntColumn get pageNumber => integer()();

  /// Хэш страницы для контроля изменений.
  TextColumn get pageSha256Hash =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Главная страница/обложка версии.
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {versionId, pageNumber},
    {versionId, pageId},
  ];

  @override
  String get tableName => 'document_version_pages';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${DocumentVersionPageConstraint.idNotBlank.constraintName}
    CHECK (length(trim(id)) > 0)
    ''',

    '''
    CONSTRAINT ${DocumentVersionPageConstraint.versionIdNotBlank.constraintName}
    CHECK (length(trim(version_id)) > 0)
    ''',

    '''
    CONSTRAINT ${DocumentVersionPageConstraint.pageIdNotBlank.constraintName}
    CHECK (length(trim(page_id)) > 0)
    ''',

    '''
    CONSTRAINT ${DocumentVersionPageConstraint.metadataHistoryIdNotBlank.constraintName}
    CHECK (
      metadata_history_id IS NULL
      OR length(trim(metadata_history_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${DocumentVersionPageConstraint.pageNumberPositive.constraintName}
    CHECK (
      page_number > 0
    )
    ''',

    '''
    CONSTRAINT ${DocumentVersionPageConstraint.pageSha256HashNotBlank.constraintName}
    CHECK (
      page_sha256_hash IS NULL
      OR length(trim(page_sha256_hash)) > 0
    )
    ''',

    '''
    CONSTRAINT ${DocumentVersionPageConstraint.pageSha256HashNoOuterWhitespace.constraintName}
    CHECK (
      page_sha256_hash IS NULL
      OR page_sha256_hash = trim(page_sha256_hash)
    )
    ''',
  ];
}

@JsonEnum(fieldRename: FieldRename.snake)
enum DocumentPageConstraint {
  idNotBlank('chk_document_pages_id_not_blank'),

  documentIdNotBlank('chk_document_pages_document_id_not_blank'),

  currentVersionPageIdNotBlank(
    'chk_document_pages_current_version_page_id_not_blank',
  );

  const DocumentPageConstraint(this.constraintName);

  final String constraintName;
}

@JsonEnum(fieldRename: FieldRename.snake)
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

@JsonEnum(fieldRename: FieldRename.snake)
enum DocumentPageTrigger {
  validateDocumentTypeOnInsert(
    'trg_document_pages_validate_document_type_on_insert',
  ),
  validateDocumentTypeOnUpdate(
    'trg_document_pages_validate_document_type_on_update',
  ),
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

@JsonEnum(fieldRename: FieldRename.snake)
enum DocumentPageRaise {
  invalidDocumentType(
    'document_pages.document_id must reference vault_items.id with type = document',
  ),
  documentIdImmutable('document_pages.document_id is immutable'),
  invalidCurrentVersionPage(
    'document_pages.current_version_page_id must belong to this document page',
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
        AND dvp.page_id = NEW.id
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
        AND dvp.page_id = NEW.id
    )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentPageRaise.invalidCurrentVersionPage.message}'
    );
  END;
  ''',
];

enum DocumentVersionPageConstraint {
  idNotBlank('chk_document_version_pages_id_not_blank'),
  versionIdNotBlank('chk_document_version_pages_version_id_not_blank'),
  pageIdNotBlank('chk_document_version_pages_page_id_not_blank'),
  metadataHistoryIdNotBlank(
    'chk_document_version_pages_metadata_history_id_not_blank',
  ),
  pageNumberPositive('chk_document_version_pages_page_number_positive'),
  pageSha256HashNotBlank(
    'chk_document_version_pages_page_sha256_hash_not_blank',
  ),
  pageSha256HashNoOuterWhitespace(
    'chk_document_version_pages_page_sha256_hash_no_outer_whitespace',
  );

  const DocumentVersionPageConstraint(this.constraintName);

  final String constraintName;
}

enum DocumentVersionPageIndex {
  versionId('idx_document_version_pages_version_id'),
  pageId('idx_document_version_pages_page_id'),
  versionPageId('idx_document_version_pages_version_id_page_id'),
  metadataHistoryId('idx_document_version_pages_metadata_history_id'),
  pageSha256Hash('idx_document_version_pages_page_sha256_hash'),
  versionPageNumber('idx_document_version_pages_version_id_page_number'),
  uniquePrimaryPerVersion('uq_document_version_pages_one_primary_per_version');

  const DocumentVersionPageIndex(this.indexName);

  final String indexName;
}

final List<String> documentVersionPagesTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.versionId.indexName} ON document_version_pages(version_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.pageId.indexName} ON document_version_pages(page_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.versionPageId.indexName} ON document_version_pages(version_id, page_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.metadataHistoryId.indexName} ON document_version_pages(metadata_history_id) WHERE metadata_history_id IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.pageSha256Hash.indexName} ON document_version_pages(page_sha256_hash) WHERE page_sha256_hash IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.versionPageNumber.indexName} ON document_version_pages(version_id, page_number);',

  // Только одна primary-страница на версию документа.
  'CREATE UNIQUE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.uniquePrimaryPerVersion.indexName} '
      'ON document_version_pages(version_id) WHERE is_primary = 1;',
];

enum DocumentVersionPageTrigger {
  preventVersionIdUpdate(
    'trg_document_version_pages_prevent_version_id_update',
  ),
  validatePageDocumentOnInsert(
    'trg_document_version_pages_validate_page_document_on_insert',
  ),
  preventUpdate('trg_document_version_pages_prevent_update');

  const DocumentVersionPageTrigger(this.triggerName);

  final String triggerName;
}

enum DocumentVersionPageRaise {
  versionIdImmutable('document_version_pages.version_id is immutable'),
  invalidPageDocument(
    'document_version_pages.page_id must belong to the same document as version_id',
  ),
  pageIsImmutable('document_version_pages rows are immutable');

  const DocumentVersionPageRaise(this.message);

  final String message;
}

final List<String> documentVersionPagesTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentVersionPageTrigger.preventVersionIdUpdate.triggerName}
  BEFORE UPDATE OF version_id ON document_version_pages
  FOR EACH ROW
  WHEN NEW.version_id <> OLD.version_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentVersionPageRaise.versionIdImmutable.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentVersionPageTrigger.validatePageDocumentOnInsert.triggerName}
  BEFORE INSERT ON document_version_pages
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM document_versions dv
    INNER JOIN document_pages dp ON dp.id = NEW.page_id
    WHERE dv.id = NEW.version_id
      AND dp.document_id = dv.document_id
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentVersionPageRaise.invalidPageDocument.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentVersionPageTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON document_version_pages
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentVersionPageRaise.pageIsImmutable.message}'
    );
  END;
  ''',
];
