import 'package:drift/drift.dart';

import '../main_store.dart';
import '../tables/otp/otp_items.dart';

part 'otp_items_dao.g.dart';

@DriftAccessor(tables: [OtpItems])
class OtpItemsDao extends DatabaseAccessor<MainStore> with _$OtpItemsDaoMixin {
  OtpItemsDao(super.db);

  Future<void> insertOtp(OtpItemsCompanion companion) {
    return into(otpItems).insert(companion);
  }

  Future<int> updateOtpByItemId(
    String itemId,
    OtpItemsCompanion companion,
  ) {
    return (update(otpItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<OtpItemsData?> getOtpByItemId(String itemId) {
    return (select(otpItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsOtpByItemId(String itemId) async {
    final row = await (selectOnly(otpItems)
          ..addColumns([otpItems.itemId])
          ..where(otpItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteOtpByItemId(String itemId) {
    return (delete(otpItems)..where((tbl) => tbl.itemId.equals(itemId))).go();
  }
}
