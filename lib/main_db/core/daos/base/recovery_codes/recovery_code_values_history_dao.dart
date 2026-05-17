import 'package:drift/drift.dart';
import '../../../models/dto_history/cards/recovery_codes_history_card_dto.dart';

import '../../../main_store.dart';
import '../../../tables/recovery_codes/recovery_code_values_history.dart';


part 'recovery_code_values_history_dao.g.dart';

@DriftAccessor(tables: [RecoveryCodeValuesHistory])
class RecoveryCodeValuesHistoryDao extends DatabaseAccessor<MainStore>
    with _$RecoveryCodeValuesHistoryDaoMixin {
  RecoveryCodeValuesHistoryDao(super.db);

  Future<int> insertRecoveryCodeValueHistory(
    RecoveryCodeValuesHistoryCompanion companion,
  ) {
    return into(recoveryCodeValuesHistory).insert(companion);
  }

  Future<void> insertRecoveryCodeValuesHistoryBatch(
    List<RecoveryCodeValuesHistoryCompanion> companions,
  ) {
    return batch((batch) {
      batch.insertAll(recoveryCodeValuesHistory, companions);
    });
  }

  Future<RecoveryCodeValuesHistoryData?> getRecoveryCodeValueHistoryById(
    int id,
  ) {
    return (select(recoveryCodeValuesHistory)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<RecoveryCodeValuesHistoryData>> getRecoveryCodeValuesByHistoryId(
    String historyId,
  ) {
    return (select(recoveryCodeValuesHistory)
          ..where((tbl) => tbl.historyId.equals(historyId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .get();
  }

  Future<List<RecoveryCodeValuesHistoryData>>
      getUsedRecoveryCodeValuesByHistoryId(
    String historyId,
  ) {
    return (select(recoveryCodeValuesHistory)
          ..where((tbl) => tbl.historyId.equals(historyId))
          ..where((tbl) => tbl.used.equals(true))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .get();
  }

  Future<List<RecoveryCodeValuesHistoryData>>
      getUnusedRecoveryCodeValuesByHistoryId(
    String historyId,
  ) {
    return (select(recoveryCodeValuesHistory)
          ..where((tbl) => tbl.historyId.equals(historyId))
          ..where((tbl) => tbl.used.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .get();
  }

  Future<int> deleteRecoveryCodeValueHistoryById(int id) {
    return (delete(recoveryCodeValuesHistory)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<int> deleteRecoveryCodeValuesHistoryByHistoryId(String historyId) {
    return (delete(recoveryCodeValuesHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }

  Future<List<RecoveryCodeValueHistorySecretDto>> getRecoveryCodeSecretsByHistoryId(
    String historyId,
  ) async {
    final rows = await (select(recoveryCodeValuesHistory)
          ..where((tbl) => tbl.historyId.equals(historyId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .get();

    return rows
        .map((r) => RecoveryCodeValueHistorySecretDto(
              id: r.id,
              code: r.code ?? '',
              used: r.used,
              usedAt: r.usedAt,
              position: r.position,
            ))
        .toList();
  }
}
