import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../../scheme/tables/recovery_codes/recovery_codes_history.dart';

part 'recovery_codes_history_dao.g.dart';

@DriftAccessor(tables: [RecoveryCodesHistory])
class RecoveryCodesHistoryDao extends DatabaseAccessor<VaultDB>
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
    return (select(
      recoveryCodesHistory,
    )..where((tbl) => tbl.historyId.equals(historyId))).getSingleOrNull();
  }

  Future<bool> existsRecoveryCodesHistoryByHistoryId(String historyId) async {
    final row =
        await (selectOnly(recoveryCodesHistory)
              ..addColumns([recoveryCodesHistory.historyId])
              ..where(recoveryCodesHistory.historyId.equals(historyId)))
            .getSingleOrNull();

    return row != null;
  }

  Future<List<RecoveryCodesHistoryData>>
  getRecoveryCodesHistoryByGeneratedAtRange({DateTime? from, DateTime? to}) {
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
    return (delete(
      recoveryCodesHistory,
    )..where((tbl) => tbl.historyId.equals(historyId))).go();
  }

  // --- HISTORY CARD BATCH METHODS ---
  Future<List<RecoveryCodesHistoryData>> getRecoveryCodesHistoryByHistoryIds(
    List<String> historyIds,
  ) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(
      recoveryCodesHistory,
    )..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, RecoveryCodesHistoryCardDataDto>>
  getRecoveryCodesHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final query = selectOnly(recoveryCodesHistory)
      ..addColumns([
        recoveryCodesHistory.historyId,
        recoveryCodesHistory.generatedAt,
        recoveryCodesHistory.oneTime,
      ])
      ..where(recoveryCodesHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(
          recoveryCodesHistory.historyId,
        )!: RecoveryCodesHistoryCardDataDto(
          generatedAt: row.read(recoveryCodesHistory.generatedAt),
          oneTime: row.read(recoveryCodesHistory.oneTime),
        ),
    };
  }
}
