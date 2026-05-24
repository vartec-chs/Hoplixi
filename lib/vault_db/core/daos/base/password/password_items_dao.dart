import 'package:drift/drift.dart';

import 'package:hoplixi/vault_db/core/vault_db.dart';
import '../../../scheme/tables/password/password_items.dart';

part 'password_items_dao.g.dart';

@DriftAccessor(tables: [PasswordItems])
class PasswordItemsDao extends DatabaseAccessor<VaultDB>
    with _$PasswordItemsDaoMixin {
  PasswordItemsDao(super.db);

  Future<void> insertPassword(PasswordItemsCompanion companion) {
    return into(passwordItems).insert(companion);
  }

  Future<int> updatePasswordByItemId(
    String itemId,
    PasswordItemsCompanion companion,
  ) {
    return (update(
      passwordItems,
    )..where((tbl) => tbl.itemId.equals(itemId))).write(companion);
  }

  Future<PasswordItemsData?> getPasswordByItemId(String itemId) {
    return (select(
      passwordItems,
    )..where((tbl) => tbl.itemId.equals(itemId))).getSingleOrNull();
  }

  Future<bool> existsPasswordByItemId(String itemId) async {
    final row =
        await (selectOnly(passwordItems)
              ..addColumns([passwordItems.itemId])
              ..where(passwordItems.itemId.equals(itemId)))
            .getSingleOrNull();

    return row != null;
  }

  Future<int> deletePasswordByItemId(String itemId) {
    return (delete(
      passwordItems,
    )..where((tbl) => tbl.itemId.equals(itemId))).go();
  }

  Future<String?> getPasswordSecretByItemId(String itemId) async {
    final row =
        await (selectOnly(passwordItems)
              ..addColumns([passwordItems.password])
              ..where(passwordItems.itemId.equals(itemId)))
            .getSingleOrNull();
    return row?.read(passwordItems.password);
  }

  Future<void> upsertPasswordItem(PasswordItemsCompanion companion) {
    return into(passwordItems).insertOnConflictUpdate(companion);
  }
}
