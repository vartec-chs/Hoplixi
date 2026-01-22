import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'categories.dart';
import 'notes.dart';

@DataClassName('DocumentsData')
class Documents extends Table {
  /// UUID документа
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Отображаемое имя: "Паспорт", "Договор аренды"
  TextColumn get title => text().withLength(min: 1, max: 255).nullable()();

  /// Тип документа: passport, contract, invoice, certificate
  TextColumn get documentType =>
      text().withLength(min: 1, max: 64).nullable()();

  /// Описание / заметки
  TextColumn get description => text().nullable()();

  /// Агрегированный OCR текст всех страниц
  TextColumn get aggregatedText => text().nullable()();

  /// Хэш версии документа (например, hash всех страниц)
  TextColumn get aggregateHash => text().nullable()();

  /// Количество страниц
  IntColumn get pageCount => integer().withDefault(const Constant(0))();

  /// Ссылка на категорию
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get noteId =>
      text().nullable().references(Notes, #id, onDelete: KeyAction.setNull)();

  /// UX-флаги
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// Системные поля
  IntColumn get usedCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  RealColumn get recentScore => real().nullable()();
  DateTimeColumn get lastUsedAt =>
      dateTime().nullable()(); // For filters and UX

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'documents';
}
