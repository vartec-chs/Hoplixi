import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../vault_items/vault_item_history.dart';
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
  TextColumn get itemHistoryId => text()
    .nullable()
    .references(VaultItemHistory, #id, onDelete: KeyAction.setNull)();

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

  /// Текущая активная версия документа.
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();

  /// UUID снимка для группировки связанных записей.
  TextColumn get snapshotId => text().nullable()();

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
        CONSTRAINT ${DocumentVersionConstraint.aggregateSha256HashNotBlank.constraintName}
        CHECK (
          aggregate_sha256_hash IS NULL
          OR length(trim(aggregate_sha256_hash)) > 0
        )
        ''',

    '''
        CONSTRAINT ${DocumentVersionConstraint.pageCountNonNegative.constraintName}
        CHECK (
          page_count >= 0
        )
        ''',
  ];
}

enum DocumentVersionConstraint {
  versionNumberPositive('chk_document_versions_version_number_positive'),
  documentTypeOtherRequired(
    'chk_document_versions_document_type_other_required',
  ),
  documentTypeOtherMustBeNull(
    'chk_document_versions_document_type_other_must_be_null',
  ),
  aggregateSha256HashNotBlank(
    'chk_document_versions_aggregate_sha256_hash_not_blank',
  ),
  pageCountNonNegative('chk_document_versions_page_count_non_negative');

  const DocumentVersionConstraint(this.constraintName);

  final String constraintName;
}

enum DocumentVersionIndex {
  snapshotId('idx_document_versions_snapshot_id'),
  documentId('idx_document_versions_document_id'),
  documentType('idx_document_versions_document_type'),
  aggregateSha256Hash('idx_document_versions_aggregate_sha256_hash'),
  createdAt('idx_document_versions_created_at'),
  uniqueCurrentPerDocument('uq_document_versions_one_current_per_document');

  const DocumentVersionIndex(this.indexName);

  final String indexName;
}

final List<String> documentVersionsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionIndex.snapshotId.indexName} ON document_versions(snapshot_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionIndex.documentId.indexName} ON document_versions(document_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionIndex.documentType.indexName} ON document_versions(document_type);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionIndex.aggregateSha256Hash.indexName} ON document_versions(aggregate_sha256_hash);',
  'CREATE INDEX IF NOT EXISTS ${DocumentVersionIndex.createdAt.indexName} ON document_versions(created_at);',

  // Только одна current-версия на документ.
  'CREATE UNIQUE INDEX IF NOT EXISTS ${DocumentVersionIndex.uniqueCurrentPerDocument.indexName} '
      'ON document_versions(document_id) WHERE is_current = 1;',
];
