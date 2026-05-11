import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../file/file_metadata.dart';
import '../vault_items/vault_items.dart';

/// Страницы документа one-to-many: document → pages.
///
/// documentId ссылается на vault_items.id.
/// Важно: логически documentId должен указывать на VaultItemType.document.
/// Это лучше проверять на уровне репозитория/сервиса или trigger'ом,
/// потому что SQLite CHECK не умеет нормально проверять другую таблицу.
@DataClassName('DocumentPagesData')
class DocumentPages extends Table {
  /// UUID страницы.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Документ-владелец FK → vault_items.id.
  TextColumn get documentId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Метаданные файла страницы.
  TextColumn get metadataId => text().nullable().references(
    FileMetadata,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Порядковый номер страницы, начиная с 1.
  IntColumn get pageNumber => integer()();

  /// OCR-текст конкретной страницы.
  ///
  /// Может быть NULL, если OCR отключён или текст не сохраняется.
  TextColumn get extractedText => text().nullable()();

  /// Хэш страницы для контроля изменений.
  TextColumn get pageHash => text().withLength(min: 1, max: 255).nullable()();

  /// Главная страница/обложка.
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  /// Количество использований/открытий страницы.
  IntColumn get usedCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  /// Дополнительные метаданные страницы в JSON-формате.
  ///
  /// Например: OCR language, dimensions, rotation, confidence,
  /// source page id, import metadata.
  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {documentId, pageNumber},
  ];

  @override
  String get tableName => 'document_pages';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${DocumentPageConstraint.pageNumberPositive.constraintName}
        CHECK (
          page_number > 0
        )
        ''',

    '''
        CONSTRAINT ${DocumentPageConstraint.extractedTextNotBlank.constraintName}
        CHECK (
          extracted_text IS NULL
          OR length(trim(extracted_text)) > 0
        )
        ''',

    '''
        CONSTRAINT ${DocumentPageConstraint.pageHashNotBlank.constraintName}
        CHECK (
          page_hash IS NULL
          OR length(trim(page_hash)) > 0
        )
        ''',

    '''
        CONSTRAINT ${DocumentPageConstraint.usedCountNonNegative.constraintName}
        CHECK (
          used_count >= 0
        )
        ''',
  ];
}

enum DocumentPageConstraint {
  pageNumberPositive('chk_document_pages_page_number_positive'),

  extractedTextNotBlank('chk_document_pages_extracted_text_not_blank'),

  pageHashNotBlank('chk_document_pages_page_hash_not_blank'),

  usedCountNonNegative('chk_document_pages_used_count_non_negative');

  const DocumentPageConstraint(this.constraintName);

  final String constraintName;
}

enum DocumentPageIndex {
  documentId('idx_document_pages_document_id'),
  metadataId('idx_document_pages_metadata_id'),
  pageHash('idx_document_pages_page_hash'),
  lastUsedAt('idx_document_pages_last_used_at'),
  uniquePrimaryPerDocument('uq_document_pages_one_primary_per_document');

  const DocumentPageIndex(this.indexName);

  final String indexName;
}

final List<String> documentPagesTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentPageIndex.documentId.indexName} ON document_pages(document_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentPageIndex.metadataId.indexName} ON document_pages(metadata_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentPageIndex.pageHash.indexName} ON document_pages(page_hash);',
  'CREATE INDEX IF NOT EXISTS ${DocumentPageIndex.lastUsedAt.indexName} ON document_pages(last_used_at);',

  // Только одна primary-страница на документ.
  'CREATE UNIQUE INDEX IF NOT EXISTS ${DocumentPageIndex.uniquePrimaryPerDocument.indexName} '
      'ON document_pages(document_id) WHERE is_primary = 1;',
];
