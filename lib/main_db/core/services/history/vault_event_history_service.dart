import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/dao/vault_items/vault_events_history_dao.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';

import '../../main_store.dart';

class VaultEventHistoryService {
  VaultEventHistoryService(this.eventsHistoryDao);

  final VaultEventsHistoryDao eventsHistoryDao;

  Future<void> writeEvent({
    required String itemId,
    required VaultItemType type,
    required VaultEventHistoryAction action,
    String? name,
    String? description,
    String? categoryId,
    String? iconRefId,
    String? snapshotHistoryId,
    VaultHistoryActorType actorType = VaultHistoryActorType.user,
  }) async {
    await eventsHistoryDao.insertVaultEvent(
      VaultEventsHistoryCompanion.insert(
        itemId: itemId,
        type: type,
        action: action,
        name: Value(name),
        description: Value(description),
        categoryId: Value(categoryId),
        iconRefId: Value(iconRefId),
        snapshotHistoryId: Value(snapshotHistoryId),
        actorType: Value(actorType),
        eventCreatedAt: Value(DateTime.now()),
      ),
    );
  }
}
