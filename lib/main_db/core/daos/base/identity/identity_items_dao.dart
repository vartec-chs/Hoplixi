import 'package:drift/drift.dart';

import '../../../main_store.dart';
import '../../../tables/identity/identity_items.dart';

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

  Future<String?> getTaxIdByItemId(String itemId) async {
    final row = await (selectOnly(identityItems)
          ..addColumns([identityItems.taxId])
          ..where(identityItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(identityItems.taxId);
  }

  Future<String?> getNationalIdByItemId(String itemId) async {
    final row = await (selectOnly(identityItems)
          ..addColumns([identityItems.nationalId])
          ..where(identityItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(identityItems.nationalId);
  }

  Future<String?> getPassportNumberByItemId(String itemId) async {
    final row = await (selectOnly(identityItems)
          ..addColumns([identityItems.passportNumber])
          ..where(identityItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(identityItems.passportNumber);
  }

  Future<String?> getDriverLicenseNumberByItemId(String itemId) async {
    final row = await (selectOnly(identityItems)
          ..addColumns([identityItems.driverLicenseNumber])
          ..where(identityItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(identityItems.driverLicenseNumber);
  }
}
