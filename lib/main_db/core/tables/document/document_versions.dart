import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../vault_items/vault_snapshots_history.dart';
import '../vault_items/vault_items.dart';
import 'document_types.dart';

/// Версии документа one-to-many: document -> versions.
///
/// documentId ссылается на vault_items.id. Логически это должен быть
/// VaultItemType.document; проверка остается на уровне сервиса/триггеров.
@DataClassName('DocumentVersionsData')
class DocumentVersions extends Table {
  /// UUID версии документа.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Документ-владелец FK -> vault_items.id.
  TextColumn get documentId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Ссылка на историю изменений документа.
  TextColumn get historyId => text().nullable().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Номер версии документа, начиная с 1.
  IntColumn get versionNumber => integer()();

  /// Тип документа snapshot: passport, contract, invoice и т.д.
  TextColumn get documentType => textEnum<DocumentType>().nullable()();

  /// Дополнительный тип документа, если documentType = other.
  TextColumn get documentTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Хэш агрегированной версии документа/страниц.
  TextColumn get aggregateSha256Hash =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Количество страниц в версии.
  IntColumn get pageCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {documentId, versionNumber},
  ];

  @override
  String get tableName => 'document_versions';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${DocumentVersionConstraint.idNotBlank.constraintName}
    CHECK (length(trim(id)) > 0)
    ''',

    '''
    CONSTRAINT ${DocumentVersionConstraint.documentIdNotBlank.constraintName}
    CHECK (length(trim(document_id)) > 0)
    ''',

    '''
    CONSTRAINT ${DocumentVersionConstraint.historyIdNotBlank.constraintName}
    CHECK (
      history_id IS NULL
      OR length(trim(history_id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${DocumentVersionConstraint.versionNumberPositive.constraintName}
    CHECK (
      version_number > 0
    )
    ''',

    '''
    CONSTRAINT ${DocumentVersionConstraint.documentTypeOtherRequired.constraintName}
    CHECK (
      document_type IS NULL
      OR document_type != 'other'
      OR (
        document_type_other IS NOT NULL
        AND length(trim(document_type_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${DocumentVersionConstraint.documentTypeOtherMustBeNull.constraintName}
    CHECK (
      document_type = 'other'
      OR document_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${DocumentVersionConstraint.documentTypeOtherNoOuterWhitespace.constraintName}
    CHECK (
      document_type_other IS NULL
      OR document_type_other = trim(document_type_other)
    )
    ''',

    '''
    CONSTRAINT ${DocumentVersionConstraint.aggregateSha256HashNotBlank.constraintName}
    CHECK (
      aggregate_sha256_hash IS NULL
      OR length(trim(aggregate_sha256_hash)) > 0
    )
    ''',

    '''
    CONSTRAINT ${DocumentVersionConstraint.aggregateSha256HashNoOuterWhitespace.constraintName}
    CHECK (
      aggregate_sha256_hash IS NULL
      OR aggregate_sha256_hash = trim(aggregate_sha256_hash)
    )
    ''',

    '''
    CONSTRAINT ${DocumentVersionConstraint.pageCountNonNegative.constraintName}
    CHECK (
      page_count >= 0
    )
    ''',

    '''
    CONSTRAINT ${DocumentVersionConstraint.createdModifiedRange.constraintName}
    CHECK (
      created_at <= modified_at
    )
    ''',
  ];
}

enum DocumentVersionConstraint {
  idNotBlank('chk_document_versions_id_not_blank'),
  documentIdNotBlank('chk_document_versions_document_id_not_blank'),
  historyIdNotBlank('chk_document_versions_history_id_not_blank'),
  versionNumberPositive('chk_document_versions_version_number_positive'),
  documentTypeOtherRequired(
    'chk_document_versions_document_type_other_required',
  ),
  documentTypeOtherMustBeNull(
    'chk_document_versions_document_type_other_must_be_null',
  ),
  documentTypeOtherNoOuterWhitespace(
    'chk_document_versions_document_type_other_no_outer_whitespace',
  ),
  aggregateSha256HashNotBlank(
    'chk_document_versions_aggregate_sha256_hash_not_blank',
  ),
  aggregateSha256HashNoOuterWhitespace(
    'chk_document_versions_aggregate_sha256_hash_no_outer_whitespace',
  ),
  pageCountNonNegative('chk_document_versions_page_count_non_negative'),
  createdModifiedRange('chk_document_versions_created_modified_range');

  const DocumentVersionConstraint(this.constraintName);

  final String constraintName;
}

enum DocumentVersionIndex {
  documentId('idx_document_versions_document_id'),
  documentType('idx_document_versions_document_type'),
  aggregateSha256Hash('idx_document_versions_aggregate_sha256_hash'),
  historyId('idx_document_versions_history_id'),
  documentCreatedAt('idx_document_versions_document_id_created_at');

  const DocumentVersionIndex(this.indexName);

  final String indexName;
}

final List<String> documentVersionsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionIndex.documentId.indexName} ON document_versions(document_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionIndex.documentType.indexName} ON document_versions(document_type) WHERE document_type IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionIndex.aggregateSha256Hash.indexName} ON document_versions(aggregate_sha256_hash) WHERE aggregate_sha256_hash IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionIndex.historyId.indexName} ON document_versions(history_id) WHERE history_id IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionIndex.documentCreatedAt.indexName} ON document_versions(document_id, created_at DESC);',
];

enum DocumentVersionTrigger {
  validateDocumentTypeOnInsert('trg_document_versions_validate_document_type_on_insert'),
  validateDocumentTypeOnUpdate('trg_document_versions_validate_document_type_on_update'),
  preventDocumentIdUpdate('trg_document_versions_prevent_document_id_update');

  const DocumentVersionTrigger(this.triggerName);

  final String triggerName;
}

enum DocumentVersionRaise {
  invalidDocumentType(
    'document_versions.document_id must reference vault_items.id with type = document',
  ),
  documentIdImmutable('document_versions.document_id is immutable');

  const DocumentVersionRaise(this.message);

  final String message;
}

final List<String> documentVersionsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentVersionTrigger.validateDocumentTypeOnInsert.triggerName}
  BEFORE INSERT ON document_versions
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
      '${DocumentVersionRaise.invalidDocumentType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentVersionTrigger.validateDocumentTypeOnUpdate.triggerName}
  BEFORE UPDATE ON document_versions
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
      '${DocumentVersionRaise.invalidDocumentType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${DocumentVersionTrigger.preventDocumentIdUpdate.triggerName}
  BEFORE UPDATE OF document_id ON document_versions
  FOR EACH ROW
  WHEN NEW.document_id <> OLD.document_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${DocumentVersionRaise.documentIdImmutable.message}'
    );
  END;
  ''',
];
