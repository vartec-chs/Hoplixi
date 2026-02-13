import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:uuid/uuid.dart';

@DataClassName('IconsData')
class Icons extends Table {
  TextColumn get id =>
      text().clientDefault(() => const Uuid().v4())(); // UUID v4
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get type => textEnum<IconType>().withLength(
    min: 1,
    max: 50,
  )(); // MIME type: png, jpg, svg, etc.
  BlobColumn get data => blob()(); // Binary image data
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'icons';
}
