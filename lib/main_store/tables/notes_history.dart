import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:uuid/uuid.dart';

@DataClassName('NotesHistoryData')
class NotesHistory extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())(); // UUID v4
  TextColumn get originalNoteId => text()(); // ID of original note
  TextColumn get action => textEnum<ActionInHistory>().withLength(
    min: 1,
    max: 50,
  )(); // 'deleted', 'modified'

  // Note content snapshot
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get deltaJson =>
      text()(); // Quill Delta JSON representation at time of action
  TextColumn get content => text()(); // Main content at time of action

  // Relations
  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName =>
      text().nullable()(); // Category name at time of action

  // State flags snapshot
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
  RealColumn get recentScore => real().nullable()(); // EWMA snapshot
  DateTimeColumn get lastUsedAt =>
      dateTime().nullable()(); // Last used snapshot

  // Timestamps
  DateTimeColumn get originalCreatedAt => dateTime().nullable()();
  DateTimeColumn get originalModifiedAt => dateTime().nullable()();
  DateTimeColumn get originalLastUsedAt => dateTime().nullable()();
  DateTimeColumn get actionAt => dateTime().clientDefault(
    () => DateTime.now(),
  )(); // When action was performed

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'notes_history';
}
