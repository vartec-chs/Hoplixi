import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/license_key/license_key_history.dart';

part 'license_key_history_dao.g.dart';

@DriftAccessor(tables: [LicenseKeyHistory])
class LicenseKeyHistoryDao extends DatabaseAccessor<MainStore>
    with _$LicenseKeyHistoryDaoMixin {
  LicenseKeyHistoryDao(super.db);

  Future<void> insertLicenseKeyHistory(LicenseKeyHistoryCompanion companion) {
    return into(licenseKeyHistory).insert(companion);
  }

  Future<LicenseKeyHistoryData?> getLicenseKeyHistoryByHistoryId(
      String historyId) {
    return (select(licenseKeyHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsLicenseKeyHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(licenseKeyHistory)
          ..addColumns([licenseKeyHistory.historyId])
          ..where(licenseKeyHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteLicenseKeyHistoryByHistoryId(String historyId) {
    return (delete(licenseKeyHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }
}
