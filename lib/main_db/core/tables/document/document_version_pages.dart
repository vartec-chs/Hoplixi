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
  TextColumn get pageSha256Hash => text().withLength(min: 1, max: 255).nullable()();

  /// Главная страница/обложка версии.
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  /// UUID снимка для группировки связанных записей.
  TextColumn get snapshotId => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {versionId, pageNumber},
  ];

  @override
  String get tableName => 'document_version_pages';

  @override
  List<String> get customConstraints => [
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
  ];
}

enum DocumentVersionPageConstraint {
  pageNumberPositive('chk_document_version_pages_page_number_positive'),
  pageSha256HashNotBlank('chk_document_version_pages_page_sha256_hash_not_blank');

  const DocumentVersionPageConstraint(this.constraintName);

  final String constraintName;
}

enum DocumentVersionPageIndex {
  snapshotId('idx_document_version_pages_snapshot_id'),
  versionId('idx_document_version_pages_version_id'),
  metadataHistoryId('idx_document_version_pages_metadata_history_id'),
  pageSha256Hash('idx_document_version_pages_page_sha256_hash'),
  uniquePrimaryPerVersion('uq_document_version_pages_one_primary_per_version');

  const DocumentVersionPageIndex(this.indexName);

  final String indexName;
}

final List<String> documentVersionPagesTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.snapshotId.indexName} ON document_version_pages(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.versionId.indexName} ON document_version_pages(version_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.metadataHistoryId.indexName} ON document_version_pages(metadata_history_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.pageSha256Hash.indexName} ON document_version_pages(page_sha256_hash);',

  // Только одна primary-страница на версию документа.
  'CREATE UNIQUE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.uniquePrimaryPerVersion.indexName} '
      'ON document_version_pages(version_id) WHERE is_primary = 1;',
];
