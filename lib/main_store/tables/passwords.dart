import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'categories.dart';

@DataClassName('PasswordsData')
class Passwords extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())(); // UUID v4
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get password => text()(); // Encrypted password
  TextColumn get url => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get login => text().nullable()(); // Username
  TextColumn get email => text().nullable()(); // Email
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Foreign key to categories
  IntColumn get usedCount =>
      integer().withDefault(const Constant(0))(); // Usage count
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // Soft delete flag
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))(); // Archived flag
  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))(); // Pinned to top flag
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // Favorite flag
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'passwords';

  @override
  List<String> get customConstraints => [
    // Constraint: must have either login OR email OR both
    'CHECK (login IS NOT NULL OR email IS NOT NULL)',
  ];
}
