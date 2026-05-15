import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/recovery_codes/recovery_codes_history.dart';

part 'recovery_codes_history_dao.g.dart';

@DriftAccessor(tables: [RecoveryCodesHistory])
class RecoveryCodesHistoryDao extends DatabaseAccessor<MainStore>
    with _$RecoveryCodesHistoryDaoMixin {
  RecoveryCodesHistoryDao(super.db);

  Future<void> insertRecoveryCodesHistory(
    RecoveryCodesHistoryCompanion companion,
  ) {
    return into(recoveryCodesHistory).insert(companion);
  }

  Future<RecoveryCodesHistoryData?> getRecoveryCodesHistoryByHistoryId(
    String historyId,
  ) {
    return (select(recoveryCodesHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsRecoveryCodesHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(recoveryCodesHistory)
          ..addColumns([recoveryCodesHistory.historyId])
          ..where(recoveryCodesHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<List<RecoveryCodesHistoryData>>
      getRecoveryCodesHistoryByGeneratedAtRange({
    DateTime? from,
    DateTime? to,
  }) {
    final query = select(recoveryCodesHistory);
    if (from != null) {
      query.where((tbl) => tbl.generatedAt.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((tbl) => tbl.generatedAt.isSmallerThanValue(to));
    }
    return query.get();
  }

  Future<int> deleteRecoveryCodesHistoryByHistoryId(String historyId) {
    return (delete(recoveryCodesHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }
}
