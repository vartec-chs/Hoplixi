import 'package:drift/drift.dart';

import '../vault_items/vault_item_history.dart';
import 'document_items.dart';

/// History-таблица для специфичных полей документа.
///
/// Данные вставляются только триггерами.
@DataClassName('DocumentHistoryData')
class DocumentHistory extends Table {
  /// PK и FK → vault_item_history.id ON DELETE CASCADE
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Тип документа snapshot.
  TextColumn get documentType => textEnum<DocumentType>().nullable()();

  /// Дополнительный тип документа, если documentType = other.
  TextColumn get documentTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Агрегированный OCR-текст всех страниц snapshot.
  ///
  /// Может быть NULL, если OCR отключён, текст не сохраняется,
  /// либо history хранит только metadata snapshot.
  TextColumn get aggregatedText => text().nullable()();

  /// Хэш агрегированной версии документа/страниц snapshot.
  TextColumn get aggregateHash =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Количество страниц snapshot.
  IntColumn get pageCount => integer().withDefault(const Constant(0))();

  /// Дополнительные метаданные snapshot.
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'document_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${DocumentHistoryConstraint.documentTypeOtherRequired.constraintName}
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
    CONSTRAINT ${DocumentHistoryConstraint.documentTypeOtherMustBeNull.constraintName}
    CHECK (
      document_type = 'other'
      OR document_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${DocumentHistoryConstraint.aggregatedTextNotBlank.constraintName}
    CHECK (
      aggregated_text IS NULL
      OR length(trim(aggregated_text)) > 0
    )
    ''',

    '''
    CONSTRAINT ${DocumentHistoryConstraint.aggregateHashNotBlank.constraintName}
    CHECK (
      aggregate_hash IS NULL
      OR length(trim(aggregate_hash)) > 0
    )
    ''',

    '''
    CONSTRAINT ${DocumentHistoryConstraint.pageCountNonNegative.constraintName}
    CHECK (
      page_count >= 0
    )
    ''',
  ];
}

enum DocumentHistoryConstraint {
  documentTypeOtherRequired(
    'chk_document_history_document_type_other_required',
  ),

  documentTypeOtherMustBeNull(
    'chk_document_history_document_type_other_must_be_null',
  ),

  aggregatedTextNotBlank('chk_document_history_aggregated_text_not_blank'),

  aggregateHashNotBlank('chk_document_history_aggregate_hash_not_blank'),

  pageCountNonNegative('chk_document_history_page_count_non_negative');

  const DocumentHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum DocumentHistoryIndex {
  documentType('idx_document_history_document_type'),
  pageCount('idx_document_history_page_count'),
  aggregateHash('idx_document_history_aggregate_hash');

  const DocumentHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> documentHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentHistoryIndex.documentType.indexName} ON document_history(document_type);',
  'CREATE INDEX IF NOT EXISTS ${DocumentHistoryIndex.pageCount.indexName} ON document_history(page_count);',
  'CREATE INDEX IF NOT EXISTS ${DocumentHistoryIndex.aggregateHash.indexName} ON document_history(aggregate_hash);',
];
