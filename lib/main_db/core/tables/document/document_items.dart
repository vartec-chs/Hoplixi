import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';
import 'document_versions.dart';

export 'document_types.dart';

/// Type-specific таблица для документов.
///
/// Все восстанавливаемые данные документа хранятся в document_versions.
/// Здесь остаётся только ссылка на текущую версию.
@DataClassName('DocumentItemsData')
class DocumentItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE.
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Текущая активная версия документа.
  TextColumn get currentVersionId => text().nullable().references(
    DocumentVersions,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'document_items';
}

enum DocumentItemIndex {
  currentVersionId('idx_document_items_current_version_id');

  const DocumentItemIndex(this.indexName);

  final String indexName;
}

final List<String> documentItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${DocumentItemIndex.currentVersionId.indexName} ON document_items(current_version_id);',
];
