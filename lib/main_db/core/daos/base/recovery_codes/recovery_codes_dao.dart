import 'package:drift/drift.dart';

import '../../../main_store.dart';
import '../../../tables/recovery_codes/recovery_codes.dart';

part 'recovery_codes_dao.g.dart';

@DriftAccessor(tables: [RecoveryCodes])
class RecoveryCodesDao extends DatabaseAccessor<MainStore>
    with _$RecoveryCodesDaoMixin {
  RecoveryCodesDao(super.db);

  Future<int> insertRecoveryCode(RecoveryCodesCompanion companion) {
    return into(recoveryCodes).insert(companion);
  }

  Future<void> insertRecoveryCodesBatch(
    List<RecoveryCodesCompanion> companions,
  ) {
    return batch((batch) {
      batch.insertAll(recoveryCodes, companions);
    });
  }

  Future<int> updateRecoveryCodeById(
    int id,
    RecoveryCodesCompanion companion,
  ) {
    return (update(recoveryCodes)..where((tbl) => tbl.id.equals(id)))
        .write(companion);
  }

  Future<RecoveryCodeData?> getRecoveryCodeById(int id) {
    return (select(recoveryCodes)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<RecoveryCodeData>> getRecoveryCodesByItemId(String itemId) {
    return (select(recoveryCodes)
          ..where((tbl) => tbl.itemId.equals(itemId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .get();
  }

  Future<List<RecoveryCodeData>> getUnusedRecoveryCodesByItemId(String itemId) {
    return (select(recoveryCodes)
          ..where((tbl) => tbl.itemId.equals(itemId))
          ..where((tbl) => tbl.used.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .get();
  }

  Future<List<RecoveryCodeData>> getUsedRecoveryCodesByItemId(String itemId) {
    return (select(recoveryCodes)
          ..where((tbl) => tbl.itemId.equals(itemId))
          ..where((tbl) => tbl.used.equals(true))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .get();
  }

  Future<int> markCodeUsed({
    required int id,
    required DateTime usedAt,
  }) {
    return (update(recoveryCodes)..where((tbl) => tbl.id.equals(id))).write(
      RecoveryCodesCompanion(
        used: const Value(true),
        usedAt: Value(usedAt),
      ),
    );
  }

  Future<int> markCodeUnused({
    required int id,
  }) {
    return (update(recoveryCodes)..where((tbl) => tbl.id.equals(id))).write(
      const RecoveryCodesCompanion(
        used: Value(false),
        usedAt: Value(null),
      ),
    );
  }

  Future<int> deleteRecoveryCodeById(int id) {
    return (delete(recoveryCodes)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> deleteRecoveryCodesByItemId(String itemId) {
    return (delete(recoveryCodes)..where((tbl) => tbl.itemId.equals(itemId)))
        .go();
  }

  Future<String?> getRecoveryCodeSecretById(int id) async {
    final row = await (selectOnly(recoveryCodes)
          ..addColumns([recoveryCodes.code])
          ..where(recoveryCodes.id.equals(id)))
        .getSingleOrNull();
    return row?.read(recoveryCodes.code);
  }

  Future<List<int>> getRecoveryCodeIdsByItemId(String itemId) async {
    final query = selectOnly(recoveryCodes)
      ..addColumns([recoveryCodes.id])
      ..where(recoveryCodes.itemId.equals(itemId));
    final rows = await query.get();
    return rows.map((r) => r.read(recoveryCodes.id)!).toList();
  }

  Future<void> replaceRecoveryCodesForItem({
    required String itemId,
    required List<RecoveryCodesCompanion> codes,
  }) async {
    await transaction(() async {
      await deleteRecoveryCodesByItemId(itemId);
      await batch((batch) {
        batch.insertAll(recoveryCodes, codes);
      });
    });
  }
}
