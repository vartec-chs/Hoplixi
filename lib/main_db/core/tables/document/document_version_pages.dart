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

  /// OCR-текст конкретной страницы версии.
  TextColumn get extractedText => text().nullable()();

  /// Хэш страницы для контроля изменений.
  TextColumn get pageHash => text().withLength(min: 1, max: 255).nullable()();

  /// Главная страница/обложка версии.
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

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
        CONSTRAINT ${DocumentVersionPageConstraint.extractedTextNotBlank.constraintName}
        CHECK (
          extracted_text IS NULL
          OR length(trim(extracted_text)) > 0
        )
        ''',

    '''
        CONSTRAINT ${DocumentVersionPageConstraint.pageHashNotBlank.constraintName}
        CHECK (
          page_hash IS NULL
          OR length(trim(page_hash)) > 0
        )
        ''',
  ];
}

enum DocumentVersionPageConstraint {
  pageNumberPositive('chk_document_version_pages_page_number_positive'),
  extractedTextNotBlank('chk_document_version_pages_extracted_text_not_blank'),
  pageHashNotBlank('chk_document_version_pages_page_hash_not_blank');

  const DocumentVersionPageConstraint(this.constraintName);

  final String constraintName;
}

enum DocumentVersionPageIndex {
  versionId('idx_document_version_pages_version_id'),
  metadataHistoryId('idx_document_version_pages_metadata_history_id'),
  pageHash('idx_document_version_pages_page_hash'),
  uniquePrimaryPerVersion('uq_document_version_pages_one_primary_per_version');

  const DocumentVersionPageIndex(this.indexName);

  final String indexName;
}

final List<String> documentVersionPagesTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.versionId.indexName} ON document_version_pages(version_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.metadataHistoryId.indexName} ON document_version_pages(metadata_history_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.pageHash.indexName} ON document_version_pages(page_hash);',

  // Только одна primary-страница на версию документа.
  'CREATE UNIQUE INDEX IF NOT EXISTS ${DocumentVersionPageIndex.uniquePrimaryPerVersion.indexName} '
      'ON document_version_pages(version_id) WHERE is_primary = 1;',
];
