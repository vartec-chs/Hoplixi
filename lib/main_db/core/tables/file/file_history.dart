import 'package:drift/drift.dart';

import '../vault_items/vault_item_history.dart';

/// History-таблица для специфичных полей файла.
///
/// Данные вставляются только триггерами.
@DataClassName('FileHistoryData')
class FileHistory extends Table {
  /// PK и FK → vault_item_history.id ON DELETE CASCADE.
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Ссылка на file_metadata snapshot.
  ///
  /// Это не FK специально: история должна хранить снимок значения,
  /// даже если текущие метаданные файла позже удалены/изменены.
  TextColumn get metadataId => text().nullable()();

  /// Дополнительные метаданные snapshot.
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'file_history';
}

enum FileHistoryIndex {
  metadataId('idx_file_history_metadata_id');

  const FileHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> fileHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${FileHistoryIndex.metadataId.indexName} ON file_history(metadata_id);',
];
