import 'package:drift/drift.dart';

import 'vault_item_history.dart';

/// History-таблица для специфичных полей файла.
@DataClassName('FileHistoryData')
class FileHistory extends Table {
  /// PK и FK → vault_item_history.id ON DELETE CASCADE
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// ID метаданных файла (snapshot)
  TextColumn get metadataId => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'file_history';
}
