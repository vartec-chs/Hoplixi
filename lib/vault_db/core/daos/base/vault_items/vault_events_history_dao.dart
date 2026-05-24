import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../../scheme/tables/vault_items/vault_events_history.dart';

part 'vault_events_history_dao.g.dart';

@DriftAccessor(tables: [VaultEventsHistory])
class VaultEventsHistoryDao extends DatabaseAccessor<VaultDB>
    with _$VaultEventsHistoryDaoMixin {
  VaultEventsHistoryDao(super.db);

  Future<int> insertVaultEvent(VaultEventsHistoryCompanion companion) {
    return into(vaultEventsHistory).insert(companion);
  }

  Future<List<VaultEventHistoryData>> getEventsByItemId(String itemId) {
    return (select(vaultEventsHistory)
          ..where((t) => t.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm.desc(t.eventCreatedAt)]))
        .get();
  }

  Future<int> clearSnapshotReference(String snapshotHistoryId) {
    return (update(
      vaultEventsHistory,
    )..where((tbl) => tbl.snapshotHistoryId.equals(snapshotHistoryId))).write(
      const VaultEventsHistoryCompanion(snapshotHistoryId: Value(null)),
    );
  }

  Stream<bool> watchHasUnseenVaultEvents() {
    final query = select(vaultEventsHistory)..limit(1);

    return query.watch().map((rows) => rows.isNotEmpty);
  }
}
