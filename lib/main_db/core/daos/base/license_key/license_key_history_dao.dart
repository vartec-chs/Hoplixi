import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

import '../../../main_store.dart';

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


  // --- HISTORY CARD BATCH METHODS ---
  Future<List<LicenseKeyHistoryData>> getLicenseKeyHistoryByHistoryIds(List<String> historyIds) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(licenseKeyHistory)..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, LicenseKeyHistoryCardDataDto>> getLicenseKeyHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final hasLicenseKeyExpr = licenseKeyHistory.licenseKey.isNotNull();
    final query = selectOnly(licenseKeyHistory)
      ..addColumns([
        licenseKeyHistory.historyId,
        licenseKeyHistory.productName,
        licenseKeyHistory.vendor,
        licenseKeyHistory.licenseType,
        licenseKeyHistory.accountEmail,
        licenseKeyHistory.accountUsername,
        licenseKeyHistory.purchaseEmail,
        licenseKeyHistory.orderNumber,
        licenseKeyHistory.purchaseDate,
        licenseKeyHistory.purchasePrice,
        licenseKeyHistory.currency,
        licenseKeyHistory.validFrom,
        licenseKeyHistory.validTo,
        licenseKeyHistory.renewalDate,
        licenseKeyHistory.seats,
        licenseKeyHistory.activationLimit,
        licenseKeyHistory.activationsUsed,
        hasLicenseKeyExpr,
      ])
      ..where(licenseKeyHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(licenseKeyHistory.historyId)!: LicenseKeyHistoryCardDataDto(
          productName: row.read(licenseKeyHistory.productName),
          vendor: row.read(licenseKeyHistory.vendor),
          licenseType: row.readWithConverter<LicenseType?, String>(licenseKeyHistory.licenseType),
          accountEmail: row.read(licenseKeyHistory.accountEmail),
          accountUsername: row.read(licenseKeyHistory.accountUsername),
          purchaseEmail: row.read(licenseKeyHistory.purchaseEmail),
          orderNumber: row.read(licenseKeyHistory.orderNumber),
          purchaseDate: row.read(licenseKeyHistory.purchaseDate),
          purchasePrice: row.read(licenseKeyHistory.purchasePrice),
          currency: row.read(licenseKeyHistory.currency),
          validFrom: row.read(licenseKeyHistory.validFrom),
          validTo: row.read(licenseKeyHistory.validTo),
          renewalDate: row.read(licenseKeyHistory.renewalDate),
          seats: row.read(licenseKeyHistory.seats),
          activationLimit: row.read(licenseKeyHistory.activationLimit),
          activationsUsed: row.read(licenseKeyHistory.activationsUsed),
          hasLicenseKey: row.read(hasLicenseKeyExpr) ?? false,
        ),
    };
  }

  Future<String?> getLicenseKeyByHistoryId(String historyId) async {
    final row = await (selectOnly(licenseKeyHistory)
          ..addColumns([licenseKeyHistory.licenseKey])
          ..where(licenseKeyHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(licenseKeyHistory.licenseKey);
  }

}
