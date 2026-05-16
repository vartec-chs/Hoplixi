import 'package:drift/drift.dart';

import '../../../main_store.dart';
import '../../../tables/vault_items/vault_events_history.dart';

part 'vault_events_history_dao.g.dart';

@DriftAccessor(tables: [VaultEventsHistory])
class VaultEventsHistoryDao extends DatabaseAccessor<MainStore>
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
}
