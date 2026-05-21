import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/daos/base/vault_items/vault_events_history_dao.dart';
import 'package:hoplixi/vault_db/core/errors/db_error.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/vault_db/core/tables/vault_items/vault_items.dart';
import 'package:result_dart/result_dart.dart';

import '../vault_db.dart';

class VaultEventHistoryRepository {
  VaultEventHistoryRepository(this.db)
    : eventsHistoryDao = VaultEventsHistoryDao(db);

  VaultDB db;

  final VaultEventsHistoryDao eventsHistoryDao;

  AsyncDbResult<Unit> writeEvent({
    required String itemId,
    required VaultItemType type,
    required VaultEventHistoryAction action,
    String? name,
    String? description,
    String? snapshotHistoryId,
    VaultHistoryActorType actorType = VaultHistoryActorType.user,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        await eventsHistoryDao.insertVaultEvent(
          VaultEventsHistoryCompanion.insert(
            itemId: itemId,
            type: type,
            action: action,
            name: Value(name),
            description: Value(description),
            snapshotHistoryId: Value(snapshotHistoryId),
            actorType: Value(actorType),
            eventCreatedAt: Value(DateTime.now()),
          ),
        );
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи события истории',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}

