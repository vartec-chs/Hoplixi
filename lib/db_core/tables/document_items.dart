import 'package:drift/drift.dart';

import 'vault_items.dart';

/// Type-specific таблица для документов.
///
/// Содержит ТОЛЬКО поля, специфичные для документа.
/// Общие поля (name/title, categoryId, isFavorite и т.д.)
/// хранятся в vault_items.
@DataClassName('DocumentItemsData')
class DocumentItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Тип документа (passport, contract, invoice и т.п.)
  TextColumn get documentType =>
      text().withLength(min: 1, max: 64).nullable()();

  /// Агрегированный OCR текст всех страниц
  TextColumn get aggregatedText => text().nullable()();

  /// Хэш версии документа
  TextColumn get aggregateHash => text().nullable()();

  /// Количество страниц
  IntColumn get pageCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'document_items';
}
