import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../file/file_metadata_history.dart';
import 'document_versions.dart';

/// Страницы конкретной версии документа.
@DataClassName('DocumentVersionPagesData')
class DocumentVersionPages extends Table {
  /// UUID страницы версии.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Версия документа FK -> document_versions.id.
  TextColumn get versionId =>
      text().references(DocumentVersions, #id, onDelete: KeyAction.cascade)();

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

enum DocumentVersionPageConstraint {
  idNotBlank('chk_document_version_pages_id_not_blank'),
  versionIdNotBlank('chk_document_version_pages_version_id_not_blank'),
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
  metadataHistoryId('idx_document_version_pages_metadata_history_id'),
  pageSha256Hash('idx_document_version_pages_page_sha256_hash'),
  versionPageNumber('idx_document_version_pages_version_id_page_number'),
  uniquePrimaryPerVersion('uq_document_version_pages_one_primary_per_version');

  const DocumentVersionPageIndex(this.indexName);

  final String indexName;
}

final List<String> documentVersionPagesTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.versionId.indexName} ON document_version_pages(version_id);',
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
  preventUpdate('trg_document_version_pages_prevent_update');

  const DocumentVersionPageTrigger(this.triggerName);

  final String triggerName;
}

enum DocumentVersionPageRaise {
  versionIdImmutable('document_version_pages.version_id is immutable'),
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
