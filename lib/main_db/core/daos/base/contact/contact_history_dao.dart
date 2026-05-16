import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';

import '../../../main_store.dart';
import '../../../tables/contact/contact_history.dart';

part 'contact_history_dao.g.dart';

@DriftAccessor(tables: [ContactHistory])
class ContactHistoryDao extends DatabaseAccessor<MainStore>
    with _$ContactHistoryDaoMixin {
  ContactHistoryDao(super.db);

  Future<void> insertContactHistory(ContactHistoryCompanion companion) {
    return into(contactHistory).insert(companion);
  }

  Future<ContactHistoryData?> getContactHistoryByHistoryId(String historyId) {
    return (select(contactHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsContactHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(contactHistory)
          ..addColumns([contactHistory.historyId])
          ..where(contactHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteContactHistoryByHistoryId(String historyId) {
    return (delete(contactHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }


  // --- HISTORY CARD BATCH METHODS ---
  Future<List<ContactHistoryData>> getContactHistoryByHistoryIds(List<String> historyIds) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(contactHistory)..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, ContactHistoryCardDataDto>> getContactHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final query = selectOnly(contactHistory)
      ..addColumns([
        contactHistory.historyId,
        contactHistory.firstName,
        contactHistory.middleName,
        contactHistory.lastName,
        contactHistory.phone,
        contactHistory.email,
        contactHistory.company,
        contactHistory.jobTitle,
        contactHistory.address,
        contactHistory.website,
        contactHistory.birthday,
        contactHistory.isEmergencyContact,
      ])
      ..where(contactHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(contactHistory.historyId)!: ContactHistoryCardDataDto(
          firstName: row.read(contactHistory.firstName),
          middleName: row.read(contactHistory.middleName),
          lastName: row.read(contactHistory.lastName),
          phone: row.read(contactHistory.phone),
          email: row.read(contactHistory.email),
          company: row.read(contactHistory.company),
          jobTitle: row.read(contactHistory.jobTitle),
          address: row.read(contactHistory.address),
          website: row.read(contactHistory.website),
          birthday: row.read(contactHistory.birthday),
          isEmergencyContact: row.read(contactHistory.isEmergencyContact),
        ),
    };
  }

}
