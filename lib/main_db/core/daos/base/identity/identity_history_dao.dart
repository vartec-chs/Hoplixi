import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';

import '../../../main_store.dart';
import '../../../tables/identity/identity_history.dart';

part 'identity_history_dao.g.dart';

@DriftAccessor(tables: [IdentityHistory])
class IdentityHistoryDao extends DatabaseAccessor<MainStore>
    with _$IdentityHistoryDaoMixin {
  IdentityHistoryDao(super.db);

  Future<void> insertIdentityHistory(IdentityHistoryCompanion companion) {
    return into(identityHistory).insert(companion);
  }

  Future<IdentityHistoryData?> getIdentityHistoryByHistoryId(String historyId) {
    return (select(identityHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsIdentityHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(identityHistory)
          ..addColumns([identityHistory.historyId])
          ..where(identityHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteIdentityHistoryByHistoryId(String historyId) {
    return (delete(identityHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }


  // --- HISTORY CARD BATCH METHODS ---
  Future<List<IdentityHistoryData>> getIdentityHistoryByHistoryIds(List<String> historyIds) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(identityHistory)..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, IdentityHistoryCardDataDto>> getIdentityHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final query = selectOnly(identityHistory)
      ..addColumns([
        identityHistory.historyId,
        identityHistory.firstName,
        identityHistory.middleName,
        identityHistory.lastName,
        identityHistory.displayName,
        identityHistory.username,
        identityHistory.email,
        identityHistory.phone,
        identityHistory.address,
        identityHistory.birthday,
        identityHistory.company,
        identityHistory.jobTitle,
        identityHistory.website,
        identityHistory.taxId,
        identityHistory.nationalId,
        identityHistory.passportNumber,
        identityHistory.driverLicenseNumber,
      ])
      ..where(identityHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(identityHistory.historyId)!: IdentityHistoryCardDataDto(
          firstName: row.read(identityHistory.firstName),
          middleName: row.read(identityHistory.middleName),
          lastName: row.read(identityHistory.lastName),
          displayName: row.read(identityHistory.displayName),
          username: row.read(identityHistory.username),
          email: row.read(identityHistory.email),
          phone: row.read(identityHistory.phone),
          address: row.read(identityHistory.address),
          birthday: row.read(identityHistory.birthday),
          company: row.read(identityHistory.company),
          jobTitle: row.read(identityHistory.jobTitle),
          website: row.read(identityHistory.website),
          taxId: row.read(identityHistory.taxId),
          nationalId: row.read(identityHistory.nationalId),
          passportNumber: row.read(identityHistory.passportNumber),
          driverLicenseNumber: row.read(identityHistory.driverLicenseNumber),
        ),
    };
  }

}
