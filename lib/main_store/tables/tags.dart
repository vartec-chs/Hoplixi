import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:uuid/uuid.dart';

@DataClassName('TagsData')
class Tags extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())(); // UUID v4
  TextColumn get name => text().unique()();
  TextColumn get color =>
      text().withDefault(const Constant('FFFFFF'))(); // Hex color code
  TextColumn get type => textEnum<TagType>()(); // notes, password, totp, mixed
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'tags';
}
