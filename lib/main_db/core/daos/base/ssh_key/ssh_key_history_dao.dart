import 'package:drift/drift.dart';

import '../../../main_store.dart';
import '../../../tables/ssh_key/ssh_key_history.dart';

part 'ssh_key_history_dao.g.dart';

@DriftAccessor(tables: [SshKeyHistory])
class SshKeyHistoryDao extends DatabaseAccessor<MainStore>
    with _$SshKeyHistoryDaoMixin {
  SshKeyHistoryDao(super.db);

  Future<void> insertSshKeyHistory(SshKeyHistoryCompanion companion) {
    return into(sshKeyHistory).insert(companion);
  }

  Future<SshKeyHistoryData?> getSshKeyHistoryByHistoryId(String historyId) {
    return (select(sshKeyHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsSshKeyHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(sshKeyHistory)
          ..addColumns([sshKeyHistory.historyId])
          ..where(sshKeyHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteSshKeyHistoryByHistoryId(String historyId) {
    return (delete(sshKeyHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }
}
