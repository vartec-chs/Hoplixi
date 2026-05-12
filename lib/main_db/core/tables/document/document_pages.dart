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
  String get tableName => 'document_pages';
}

enum DocumentPageIndex {
  documentId('idx_document_pages_document_id'),
  currentVersionPageId('idx_document_pages_current_version_page_id');

  const DocumentPageIndex(this.indexName);

  final String indexName;
}

final List<String> documentPagesTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentPageIndex.documentId.indexName} ON document_pages(document_id);',
  'CREATE INDEX IF NOT EXISTS ${DocumentPageIndex.currentVersionPageId.indexName} ON document_pages(current_version_page_id);',
];
