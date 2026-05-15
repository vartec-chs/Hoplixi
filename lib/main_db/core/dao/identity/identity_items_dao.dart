import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/identity/identity_items.dart';

part 'identity_items_dao.g.dart';

@DriftAccessor(tables: [IdentityItems])
class IdentityItemsDao extends DatabaseAccessor<MainStore>
    with _$IdentityItemsDaoMixin {
  IdentityItemsDao(super.db);

  Future<void> insertIdentity(IdentityItemsCompanion companion) {
    return into(identityItems).insert(companion);
  }

  Future<int> updateIdentityByItemId(
    String itemId,
    IdentityItemsCompanion companion,
  ) {
    return (update(identityItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<IdentityItemsData?> getIdentityByItemId(String itemId) {
    return (select(identityItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsIdentityByItemId(String itemId) async {
    final row = await (selectOnly(identityItems)
          ..addColumns([identityItems.itemId])
          ..where(identityItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteIdentityByItemId(String itemId) {
    return (delete(identityItems)..where((tbl) => tbl.itemId.equals(itemId))).go();
  }
}
