import 'package:hoplixi/main_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/main_db/core/errors/db_result.dart';
import 'package:hoplixi/main_db/core/services/history/store_history_policy_service.dart';
import 'package:hoplixi/main_db/core/services/history/vault_event_history_service.dart';
import 'package:hoplixi/main_db/core/services/history/vault_snapshot_writer.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:result_dart/result_dart.dart';

class VaultHistoryService {
  VaultHistoryService({
    required this.policyService,
    required this.snapshotWriter,
    required this.eventHistoryService,
  });

  final StoreHistoryPolicyService policyService;
  final VaultSnapshotWriter snapshotWriter;
  final VaultEventHistoryService eventHistoryService;

  Future<DbResult<String>?> snapshotAfterCreate({
    required VaultItemType type,
    required Object createdView,
    required VaultEventHistoryAction action,
    bool includeSecrets = true,
    bool includeRelations = true,
  }) async {
    try {
      if (!await policyService.isHistoryEnabled()) {
        return null;
      }

      final id = await snapshotWriter.writeSnapshot(
        type: type,
        view: createdView,
        action: action,
        includeSecrets: includeSecrets,
        includeRelations: includeRelations,
      );
      return Success(id);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<DbResult<String>?> snapshotBeforeUpdate({
    required VaultItemType type,
    required Object oldView,
    required VaultEventHistoryAction action,
    bool includeSecrets = true,
    bool includeRelations = true,
  }) async {
    try {
      if (!await policyService.isHistoryEnabled()) {
        return null;
      }

      final id = await snapshotWriter.writeSnapshot(
        type: type,
        view: oldView,
        action: action,
        includeSecrets: includeSecrets,
        includeRelations: includeRelations,
      );
      return Success(id);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

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
      // Согласно рекомендации: event пишем всегда, snapshot только если включен.
      await eventHistoryService.writeEvent(
        itemId: itemId,
        type: type,
        action: action,
        name: name,
        description: description,
        categoryId: categoryId,
        iconRefId: iconRefId,
        snapshotHistoryId: snapshotHistoryId,
        actorType: actorType,
      );
      return const Success(unit);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }
}
