import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/password/password_history.dart';

part 'password_history_dao.g.dart';

@DriftAccessor(tables: [PasswordHistory])
class PasswordHistoryDao extends DatabaseAccessor<MainStore>
    with _$PasswordHistoryDaoMixin {
  PasswordHistoryDao(super.db);

  Future<void> insertPasswordHistory(PasswordHistoryCompanion companion) {
    return into(passwordHistory).insert(companion);
  }

  Future<PasswordHistoryData?> getPasswordHistoryByHistoryId(String historyId) {
    return (select(passwordHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsPasswordHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(passwordHistory)
          ..addColumns([passwordHistory.historyId])
          ..where(passwordHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deletePasswordHistoryByHistoryId(String historyId) {
    return (delete(passwordHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }
}
