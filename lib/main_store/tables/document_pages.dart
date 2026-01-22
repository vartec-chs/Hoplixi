import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'documents.dart';
import 'file_metadata.dart';
import 'files.dart';

@DataClassName('DocumentPagesData')
class DocumentPages extends Table {
  /// UUID страницы
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Документ-владелец
  TextColumn get documentId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();

  /// Файл-страница (jpeg/png/pdf)
  TextColumn get fileId =>
      text().references(Files, #id, onDelete: KeyAction.restrict)();

  /// Метаданные файла страницы
  TextColumn get metadataId => text().nullable().references(
    FileMetadata,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Порядковый номер страницы (1..N)
  IntColumn get pageNumber => integer()();

  /// OCR конкретной страницы
  TextColumn get extractedText => text().nullable()();

  /// Хэш страницы (для контроля изменений)
  TextColumn get pageHash => text().nullable()();

  /// Главная страница (обложка)
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  /// Системные поля
  IntColumn get usedCount =>
      integer().withDefault(const Constant(0))(); // Usage count
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get lastUsedAt =>
      dateTime().nullable()(); // For filters and UX

  @override
  Set<Column> get primaryKey => {id};

  /// Запрещаем дублирование номеров страниц в документе
  @override
  List<Set<Column>> get uniqueKeys => [
    {documentId, pageNumber},
  ];

  @override
  String get tableName => 'document_pages';
}
