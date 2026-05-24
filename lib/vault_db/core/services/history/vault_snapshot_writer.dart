import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/core/services/history/custom_fields/custom_fields_snapshot_service.dart';
import 'package:uuid/uuid.dart';

import '../../daos/base/vault_items/vault_snapshots_history_dao.dart';
import '../../errors/db_error.dart';
import '../../errors/db_exception_mapper.dart';
import '../../errors/db_result.dart';
import '../../models/dto/dto.dart';
import '../../scheme/tables/vault_items/vault_events_history.dart';
import '../relations/snapshot_relations_service.dart';
import 'snapshot_handlers/snapshot_handlers.dart';

class VaultSnapshotWriter {
  VaultSnapshotWriter({
    required this.vaultSnapshotsHistoryDao,
    required this.snapshotRelationsService,
    required this.customFieldsSnapshotService,
    required this.handlerRegistry,
  });

  final VaultSnapshotsHistoryDao vaultSnapshotsHistoryDao;
  final SnapshotRelationsService snapshotRelationsService;
  final CustomFieldsSnapshotService customFieldsSnapshotService;
  final VaultSnapshotTypeHandlerRegistry handlerRegistry;

  AsyncDbResult<String> writeSnapshot({
    required VaultEntityViewDto view,
    required VaultEventHistoryAction action,
    bool includeSecrets = true,
    bool includeRelations = true,
  }) {
    return ResultUtils.tryCatchAsync(() async {
      final item = view.item;

      final historyId = (await _writeBaseSnapshot(item, action)).getOrThrow();

      final handler = handlerRegistry.get(item.type);
      if (handler == null) {
        throw DBCoreError.validation(
          code: 'history.snapshot.unsupported_type',
          message: 'Snapshot для типа ${item.type.name} не поддерживается',
          entity: item.type.name,
        );
      }

      (await handler.writeTypeSnapshot(
        historyId: historyId,
        view: view,
        includeSecrets: includeSecrets,
      )).getOrThrow();

      (await customFieldsSnapshotService.snapshotCustomFieldsForItem(
        snapshotHistoryId: historyId,
        itemId: item.itemId,
        includeSecrets: includeSecrets,
      )).getOrThrow();

      if (includeRelations) {
        (await snapshotRelationsService.snapshotTagsForItem(
          historyId: historyId,
          itemId: item.itemId,
        )).getOrThrow();

        (await snapshotRelationsService.snapshotLinksForItem(
          historyId: historyId,
          itemId: item.itemId,
        )).getOrThrow();
      }

      return historyId;
    }, (e, st) => e is DBCoreError ? e : mapDbException(e, st));
  }

  AsyncDbResult<String> _writeBaseSnapshot(
    VaultItemViewDto item,
    VaultEventHistoryAction action,
  ) {
    return ResultUtils.tryCatchAsync(() async {
      final historyId = const Uuid().v4();
      final now = DateTime.now();

      final categoryHistoryIdOpt =
          (await snapshotRelationsService.snapshotCategoryForItem(
            categoryId: item.categoryId,
            itemId: item.itemId,
            snapshotId: historyId,
          )).getOrThrow();

      await vaultSnapshotsHistoryDao.insertVaultSnapshot(
        VaultSnapshotsHistoryCompanion.insert(
          id: Value(historyId),
          itemId: item.itemId,
          action: action,
          type: item.type,
          name: item.name,
          description: Value(item.description),
          categoryId: Value(item.categoryId),
          categoryHistoryId: Value(categoryHistoryIdOpt.getOrNull()),
          iconRefId: Value(item.iconRefId),
          usedCount: Value(item.usedCount),
          isFavorite: Value(item.isFavorite),
          isArchived: Value(item.isArchived),
          isPinned: Value(item.isPinned),
          isDeleted: Value(item.isDeleted),
          createdAt: item.createdAt,
          modifiedAt: item.modifiedAt,
          lastUsedAt: Value(item.lastUsedAt),
          archivedAt: Value(item.archivedAt),
          deletedAt: Value(item.deletedAt),
          recentScore: Value(item.recentScore),
          historyCreatedAt: Value(now),
        ),
      );

      return historyId;
    }, (e, st) => e is DBCoreError ? e : mapDbException(e, st));
  }
}
