import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum DocumentType {
  passport,
  idCard,
  driverLicense,
  contract,
  invoice,
  receipt,
  certificate,
  insurance,
  tax,
  medical,
  legal,
  financial,
  other,
}

/// Type-specific таблица для документов.
///
/// Содержит только поля, специфичные для документа.
/// Общие поля: name/title, description, categoryId, isFavorite и т.д.
/// хранятся в vault_items.
@DataClassName('DocumentItemsData')
class DocumentItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Тип документа: passport, contract, invoice и т.д.
  TextColumn get documentType => textEnum<DocumentType>().nullable()();

  /// Дополнительный тип документа, если documentType = other.
  TextColumn get documentTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Агрегированный OCR-текст всех страниц.
  ///
  /// Может быть NULL, если OCR отключён или пользователь не хочет хранить
  /// распознанный текст.
  TextColumn get aggregatedText => text().nullable()();

  /// Хэш текущей агрегированной версии документа/страниц.
  TextColumn get aggregateHash =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Количество страниц.
  IntColumn get pageCount => integer().withDefault(const Constant(0))();

  /// Дополнительные метаданные в JSON-формате.
  ///
  /// Например: страна, номер документа, issuing authority, OCR language,
  /// source, import info, classification confidence.
  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'document_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${DocumentItemConstraint.documentTypeOtherRequired.constraintName}
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
    CONSTRAINT ${DocumentItemConstraint.documentTypeOtherMustBeNull.constraintName}
    CHECK (
      document_type = 'other'
      OR document_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${DocumentItemConstraint.aggregatedTextNotBlank.constraintName}
    CHECK (
      aggregated_text IS NULL
      OR length(trim(aggregated_text)) > 0
    )
    ''',

    '''
    CONSTRAINT ${DocumentItemConstraint.aggregateHashNotBlank.constraintName}
    CHECK (
      aggregate_hash IS NULL
      OR length(trim(aggregate_hash)) > 0
    )
    ''',

    '''
    CONSTRAINT ${DocumentItemConstraint.pageCountNonNegative.constraintName}
    CHECK (
      page_count >= 0
    )
    ''',
  ];
}

enum DocumentItemConstraint {
  documentTypeOtherRequired('chk_document_items_document_type_other_required'),

  documentTypeOtherMustBeNull(
    'chk_document_items_document_type_other_must_be_null',
  ),

  aggregatedTextNotBlank('chk_document_items_aggregated_text_not_blank'),

  aggregateHashNotBlank('chk_document_items_aggregate_hash_not_blank'),

  pageCountNonNegative('chk_document_items_page_count_non_negative');

  const DocumentItemConstraint(this.constraintName);

  final String constraintName;
}

enum DocumentItemIndex {
  documentType('idx_document_items_document_type'),
  pageCount('idx_document_items_page_count'),
  aggregateHash('idx_document_items_aggregate_hash');

  const DocumentItemIndex(this.indexName);

  final String indexName;
}

final List<String> documentItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentItemIndex.documentType.indexName} ON document_items(document_type);',
  'CREATE INDEX IF NOT EXISTS ${DocumentItemIndex.pageCount.indexName} ON document_items(page_count);',
  'CREATE INDEX IF NOT EXISTS ${DocumentItemIndex.aggregateHash.indexName} ON document_items(aggregate_hash);',
];
