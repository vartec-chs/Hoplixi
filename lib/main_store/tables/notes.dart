import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'categories.dart';

@DataClassName('NotesData')
class Notes extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())(); // UUID v4
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get deltaJson => text()(); // Quill Delta JSON representation
  TextColumn get content => text()(); // Main content of the note
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Foreign key to categories

  IntColumn get usedCount =>
      integer().withDefault(const Constant(0))(); // Usage count
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // Favorite flag
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // Soft delete flag
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))(); // Archived flag
  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))(); // Pinned to top flag
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
  String get tableName => 'notes';
}
