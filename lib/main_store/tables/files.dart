import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'categories.dart';
import 'file_metadata.dart';
import 'notes.dart';

@DataClassName('FilesData')
class Files extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())(); // UUID v4
  TextColumn get metadataId => text().nullable().references(
    FileMetadata,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Foreign key to file metadata
  TextColumn get name => text().withLength(min: 1, max: 255)(); // Display name
  TextColumn get description => text().nullable()(); // Description
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Foreign key to categories
  TextColumn get noteId => text().nullable().references(
    Notes,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Foreign key to notes

  IntColumn get usedCount =>
      integer().withDefault(const Constant(0))(); // Usage count
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // Favorite flag
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))(); // Archived flag
  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))(); // Pinned to top flag
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // Soft delete flag
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  RealColumn get recentScore => real().nullable()(); // EWMA for sorting
  DateTimeColumn get lastUsedAt =>
      dateTime().nullable()(); // For filters and UX

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'files';
}
