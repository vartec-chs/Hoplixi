import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// Meta table for database information
@DataClassName('StoreMeta')
class StoreMetaTable extends Table {
  TextColumn get id =>
      text().clientDefault(() => const Uuid().v4())(); // UUID v4
  TextColumn get name => text().withLength(min: 4)();
  TextColumn get description => text().nullable()();
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();
  TextColumn get attachmentKey => text()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get lastOpenedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  TextColumn get version => text().withDefault(const Constant('1.0.0'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'store_meta';
}
