import 'package:hoplixi/main_db/core/services/history/store_history_policy_service.dart';
import 'package:hoplixi/main_db/core/services/history/vault_event_history_service.dart';
import 'package:hoplixi/main_db/core/services/history/vault_snapshot_writer.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';

class VaultHistoryService {
  VaultHistoryService({
    required this.policyService,
    required this.snapshotWriter,
    required this.eventHistoryService,
  });

  final StoreHistoryPolicyService policyService;
  final VaultSnapshotWriter snapshotWriter;
  final VaultEventHistoryService eventHistoryService;

  Future<String?> snapshotAfterCreate({
    required VaultItemType type,
    required Object createdView,
    required VaultEventHistoryAction action,
    bool includeSecrets = true,
    bool includeRelations = true,
  }) async {
    if (!await policyService.isHistoryEnabled()) {
      return null;
    }

    return await snapshotWriter.writeSnapshot(
      type: type,
      view: createdView,
      action: action,
      includeSecrets: includeSecrets,
      includeRelations: includeRelations,
    );
  }

  Future<String?> snapshotBeforeUpdate({
    required VaultItemType type,
    required Object oldView,
    required VaultEventHistoryAction action,
    bool includeSecrets = true,
    bool includeRelations = true,
  }) async {
    if (!await policyService.isHistoryEnabled()) {
      return null;
    }

    return await snapshotWriter.writeSnapshot(
      type: type,
      view: oldView,
      action: action,
      includeSecrets: includeSecrets,
      includeRelations: includeRelations,
    );
  }

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
  }
}
