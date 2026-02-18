import 'package:drift/drift.dart';

import 'vault_item_history.dart';

/// History-таблица для специфичных полей документа.
@DataClassName('DocumentHistoryData')
class DocumentHistory extends Table {
  /// PK и FK → vault_item_history.id ON DELETE CASCADE
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Тип документа (snapshot)
  TextColumn get documentType => text().nullable()();

  /// Агрегированный OCR текст (snapshot)
  TextColumn get aggregatedText => text().nullable()();

  /// Хэш документа (snapshot)
  TextColumn get aggregateHash => text().nullable()();

  /// Количество страниц (snapshot)
  IntColumn get pageCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'document_history';
}
