import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

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


  // --- HISTORY CARD BATCH METHODS ---
  Future<List<SshKeyHistoryData>> getSshKeyHistoryByHistoryIds(List<String> historyIds) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(sshKeyHistory)..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, SshKeyHistoryCardDataDto>> getSshKeyHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final hasPrivateKeyExpr = sshKeyHistory.privateKey.isNotNull();
    final query = selectOnly(sshKeyHistory)
      ..addColumns([
        sshKeyHistory.historyId,
        sshKeyHistory.publicKey,
        sshKeyHistory.keyType,
        sshKeyHistory.keySize,
        hasPrivateKeyExpr,
      ])
      ..where(sshKeyHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(sshKeyHistory.historyId)!: SshKeyHistoryCardDataDto(
          publicKey: row.read(sshKeyHistory.publicKey),
          keyType: row.readWithConverter<SshKeyType?, String>(sshKeyHistory.keyType),
          keySize: row.read(sshKeyHistory.keySize),
          hasPrivateKey: row.read(hasPrivateKeyExpr) ?? false,
        ),
    };
  }

  Future<String?> getPrivateKeyByHistoryId(String historyId) async {
    final row = await (selectOnly(sshKeyHistory)
          ..addColumns([sshKeyHistory.privateKey])
          ..where(sshKeyHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(sshKeyHistory.privateKey);
  }

}
