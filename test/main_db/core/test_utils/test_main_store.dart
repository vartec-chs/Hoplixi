import 'package:drift/native.dart';
import 'package:hoplixi/main_db/core/main_store.dart';

MainStore createTestStore() {
  final db = MainStore(NativeDatabase.memory());
  return db;
}
