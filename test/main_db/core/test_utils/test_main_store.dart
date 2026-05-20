import 'package:drift/native.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

VaultDB createTestStore() {
  final db = VaultDB(NativeDatabase.memory());
  return db;
}
