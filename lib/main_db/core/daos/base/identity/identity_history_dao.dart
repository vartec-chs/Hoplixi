import 'package:drift/drift.dart';

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
}
