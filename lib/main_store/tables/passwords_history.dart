import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:uuid/uuid.dart';

@DataClassName('PasswordsHistoryData')
class PasswordsHistory extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())(); // UUID v4
  TextColumn get originalPasswordId => text()(); // ID of original password
  TextColumn get action => textEnum<ActionInHistory>().withLength(
    min: 1,
    max: 50,
  )(); // 'deleted', 'modified'
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get password =>
      text().nullable()(); // Encrypted password (nullable for privacy)
  TextColumn get url => text().nullable()();
  TextColumn get noteId => text().nullable()(); // Foreign key to notes
  TextColumn get login => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName =>
      text().nullable()(); // Category name at time of action
  TextColumn get tags => text().nullable()(); // JSON array of tag names
  IntColumn get usedCount =>
      integer().withDefault(const Constant(0))(); // Usage count
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))(); // Archived flag
  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))(); // Pinned to top flag
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // Favorite flag
  RealColumn get recentScore => real().nullable()(); // EWMA snapshot
  DateTimeColumn get lastUsedAt =>
      dateTime().nullable()(); // Last used snapshot
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // Soft delete flag
  DateTimeColumn get originalCreatedAt => dateTime().nullable()();
  DateTimeColumn get originalModifiedAt => dateTime().nullable()();
  DateTimeColumn get originalLastUsedAt => dateTime().nullable()();
  DateTimeColumn get actionAt => dateTime().clientDefault(
    () => DateTime.now(),
  )(); // When action was performed

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'passwords_history';
}
