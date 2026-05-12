import 'package:drift/drift.dart';

import '../vault_items/vault_item_history.dart';
import 'file_metadata_history.dart';

/// History-таблица для специфичных полей файла.
///
/// Данные вставляются только триггерами.
@DataClassName('FileHistoryData')
class FileHistory extends Table {
  /// PK и FK → vault_item_history.id ON DELETE CASCADE.
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Ссылка на snapshot file_metadata_history.
  ///
  /// FK можно ставить, потому что это ссылка не на live file_metadata,
  /// а на immutable history snapshot.
  TextColumn get metadataHistoryId => text().nullable().references(
    FileMetadataHistory,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Дополнительные метаданные snapshot.
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'file_history';
}

enum FileHistoryIndex {
  metadataHistoryId('idx_file_history_metadata_history_id');

  const FileHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> fileHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${FileHistoryIndex.metadataHistoryId.indexName} ON file_history(metadata_history_id);',
];
