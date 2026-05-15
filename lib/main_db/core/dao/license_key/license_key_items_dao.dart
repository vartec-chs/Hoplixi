import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/license_key/license_key_items.dart';

part 'license_key_items_dao.g.dart';

@DriftAccessor(tables: [LicenseKeyItems])
class LicenseKeyItemsDao extends DatabaseAccessor<MainStore>
    with _$LicenseKeyItemsDaoMixin {
  LicenseKeyItemsDao(super.db);

  Future<void> insertLicenseKey(LicenseKeyItemsCompanion companion) {
    return into(licenseKeyItems).insert(companion);
  }

  Future<int> updateLicenseKeyByItemId(
    String itemId,
    LicenseKeyItemsCompanion companion,
  ) {
    return (update(licenseKeyItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<LicenseKeyItemsData?> getLicenseKeyByItemId(String itemId) {
    return (select(licenseKeyItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsLicenseKeyByItemId(String itemId) async {
    final row = await (selectOnly(licenseKeyItems)
          ..addColumns([licenseKeyItems.itemId])
          ..where(licenseKeyItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteLicenseKeyByItemId(String itemId) {
    return (delete(licenseKeyItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .go();
  }
}
