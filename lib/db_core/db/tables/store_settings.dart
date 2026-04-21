import 'package:drift/drift.dart';

@DataClassName('StoreSetting')
class StoreSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};

  @override
  String get tableName => 'store_settings';
}
