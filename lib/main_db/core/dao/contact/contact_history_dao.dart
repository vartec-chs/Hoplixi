import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/contact/contact_history.dart';

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
}
