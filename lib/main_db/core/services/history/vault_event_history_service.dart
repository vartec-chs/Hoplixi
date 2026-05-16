import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/daos/base/vault_items/vault_events_history_dao.dart';
import 'package:hoplixi/main_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/main_db/core/errors/db_result.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:result_dart/result_dart.dart';

import '../../main_store.dart';

class VaultEventHistoryService {
  VaultEventHistoryService(this.eventsHistoryDao);

  final VaultEventsHistoryDao eventsHistoryDao;

  Future<DbResult<Unit>> writeEvent({
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
    try {
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
      return const Success(unit);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }
}
