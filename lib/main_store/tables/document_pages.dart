import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'file_metadata.dart';
import 'vault_items.dart';

/// Страницы документа (one-to-many: document → pages).
///
/// Теперь documentId ссылается на vault_items.id.
@DataClassName('DocumentPagesData')
class DocumentPages extends Table {
  /// UUID страницы
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Документ-владелец (FK → vault_items.id)
  TextColumn get documentId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

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
  IntColumn get usedCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {documentId, pageNumber},
  ];

  @override
  String get tableName => 'document_pages';
}
