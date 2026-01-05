import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:uuid/uuid.dart';

@DataClassName('FilesHistoryData')
class FilesHistory extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())(); // UUID v4
  TextColumn get originalFileId => text()(); // ID of original file
  TextColumn get action => textEnum<ActionInHistory>().withLength(
    min: 1,
    max: 50,
  )(); // 'deleted', 'modified'

  // File data snapshot
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get fileName => text()(); // Original file name
  TextColumn get fileExtension => text()(); // File extension
  TextColumn get filePath => text()(); // Relative path from files directory
  TextColumn get mimeType => text()(); // MIME type
  IntColumn get fileSize => integer()(); // File size in bytes
  TextColumn get fileHash =>
      text().nullable()(); // SHA256 hash for integrity check

  // Relations
  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName =>
      text().nullable()(); // Category name at time of action

  // State flags snapshot
  IntColumn get usedCount =>
      integer().withDefault(const Constant(0))(); // Usage count
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // Favorite flag
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))(); // Archived flag
  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))(); // Pinned to top flag
  RealColumn get recentScore => real().nullable()(); // EWMA snapshot
  DateTimeColumn get lastUsedAt =>
      dateTime().nullable()(); // Last used snapshot
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // Soft delete flag

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
  String get tableName => 'files_history';
}
