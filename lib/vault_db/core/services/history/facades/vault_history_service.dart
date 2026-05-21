import 'package:hoplixi/vault_db/core/errors/db_error.dart';
import 'package:hoplixi/vault_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_event_history_repository.dart';
import 'package:hoplixi/vault_db/core/services/history/policy/store_history_policy_service.dart';
import 'package:hoplixi/vault_db/core/services/history/vault_snapshot_writer.dart';
import 'package:hoplixi/vault_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/vault_db/core/tables/vault_items/vault_items.dart';
import 'package:result_dart/result_dart.dart';

import '../../../models/dto/vault_item_base_dto.dart';

class VaultHistoryService {
  VaultHistoryService({
    required this.policyService,
    required this.snapshotWriter,
    required this.eventHistoryRepository,
  });

  final StoreHistoryPolicyService policyService;
  final VaultSnapshotWriter snapshotWriter;
  final VaultEventHistoryRepository eventHistoryRepository;

  AsyncDbResult<Optional<String>> snapshotAfterCreate({
    required VaultEntityViewDto createdView,
    required VaultEventHistoryAction action,
    bool includeSecrets = true,
    bool includeRelations = true,
  }) {
    return ResultUtils.tryCatchAsync(() async {
      if (!await policyService.isHistoryEnabled()) {
        return const None();
      }

      final result = await snapshotWriter.writeSnapshot(
        view: createdView,
        action: action,
        includeSecrets: includeSecrets,
        includeRelations: includeRelations,
      );
      return Some(result.getOrThrow());
    }, (e, st) => e is DBCoreError ? e : mapDbException(e, st));
  }

  AsyncDbResult<Optional<String>> snapshotBeforeUpdate({
    required VaultEntityViewDto oldView,
    required VaultEventHistoryAction action,
    bool includeSecrets = true,
    bool includeRelations = true,
  }) {
    return ResultUtils.tryCatchAsync(() async {
      if (!await policyService.isHistoryEnabled()) {
        return const None();
      }

      final result = await snapshotWriter.writeSnapshot(
        view: oldView,
        action: action,
        includeSecrets: includeSecrets,
        includeRelations: includeRelations,
      );
      return Some(result.getOrThrow());
    }, (e, st) => e is DBCoreError ? e : mapDbException(e, st));
  }

  AsyncDbResult<Unit> writeEvent({
    required String itemId,
    required VaultItemType type,
    required VaultEventHistoryAction action,
    String? name,
    String? description,
    String? snapshotHistoryId,
    VaultHistoryActorType actorType = VaultHistoryActorType.user,
  }) {
    return ResultUtils.tryCatchAsync(() async {
      // Согласно рекомендации: event пишем всегда, snapshot только если включен.
      (await eventHistoryRepository.writeEvent(
        itemId: itemId,
        type: type,
        action: action,
        name: name,
        description: description,
        snapshotHistoryId: snapshotHistoryId,
        actorType: actorType,
      )).getOrThrow();
      return unit;
    }, (e, st) => e is DBCoreError ? e : mapDbException(e, st));
  }
}
