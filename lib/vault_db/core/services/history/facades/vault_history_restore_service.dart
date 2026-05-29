import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_event_history_repository.dart';
import 'package:hoplixi/vault_db/core/services/history/history.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_exception_mapper.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_events_history.dart';
import '../../utils/vault_typed_view_resolver.dart';

class VaultHistoryRestoreService {
  VaultHistoryRestoreService({
    required this.loader,
    required this.policy,
    required this.db,
    required this.vaultItemsDao,
    required this.historyModules,
    required this.customFieldsRestoreService,
    required this.tagsRestoreService,
    required this.itemLinksRestoreService,
    required this.viewResolver,
    required this.snapshotWriter,
    required this.eventHistoryRepository,
  });

  final VaultHistoryNormalizedLoader loader;
  final VaultHistoryRestorePolicyService policy;
  final VaultDB db;
  final VaultItemsDao vaultItemsDao;
  final VaultItemHistoryModules historyModules;
  final CustomFieldsRestoreService customFieldsRestoreService;
  final TagsRestoreService tagsRestoreService;
  final ItemLinksRestoreService itemLinksRestoreService;
  final VaultTypedViewResolver viewResolver;
  final VaultSnapshotWriter snapshotWriter;
  final VaultEventHistoryRepository eventHistoryRepository;

  AsyncDBResult<Unit> restoreRevision({
    required String historyId,
    bool recreate = false,
  }) {
    return tryCatchAsync(() async {
      final selectedOpt = (await loader.loadHistorySnapshot(
        historyId,
      )).getOrThrow();
      final selected = selectedOpt.fold(
        (s) => s,
        () => throw DBCoreError.notFound(
          entity: 'HistorySnapshot',
          id: historyId,
        ),
      );

      if (!policy.isRestorable(selected)) {
        throw const DBCoreError.validation(
          code: 'history.restore.not_restorable',
          message: 'Эта ревизия не может быть восстановлена',
        );
      }

      final handler = historyModules.restoreHandler(selected.base.type);
      if (handler == null) {
        throw DBCoreError.validation(
          code: 'history.restore.unsupported_type',
          message:
              'Восстановление для типа ${selected.base.type.name} не поддерживается',
        );
      }

      return await db.transaction(() async {
        String? beforeRestoreSnapshotId;

        final currentView = await viewResolver.getView(
          itemId: selected.base.itemId,
          type: selected.base.type,
        );

        if (currentView == null && !recreate) {
          throw DBCoreError.notFound(
            entity: selected.base.type.name,
            id: selected.base.itemId,
            message:
                'Live item not found. Use recreate=true to restore deleted physical item.',
          );
        }

        if (currentView != null) {
          final snapshotRes = await snapshotWriter.writeSnapshot(
            view: currentView,
            action: VaultEventHistoryAction.restored,
            includeSecrets: true,
            includeRelations: true,
          );

          beforeRestoreSnapshotId = snapshotRes.getOrThrow();
        }

        await vaultItemsDao.upsertVaultItem(
          VaultItemsCompanion(
            id: Value(selected.base.itemId),
            type: Value(selected.base.type),
            name: Value(selected.base.name),
            description: Value(selected.base.description),
            categoryId: Value(selected.base.categoryId),
            iconRefId: Value(selected.base.iconRefId),
            usedCount: Value(selected.base.usedCount),
            isFavorite: Value(selected.base.isFavorite),
            isArchived: Value(selected.base.isArchived),
            isPinned: Value(selected.base.isPinned),
            isDeleted: const Value(false), // Always restore as active
            createdAt: Value(selected.base.createdAt),
            modifiedAt: Value(DateTime.now()), // Updated modification time
            lastUsedAt: Value(selected.base.lastUsedAt),
            archivedAt: Value(selected.base.archivedAt),
            deletedAt: const Value(null),
            recentScore: Value(selected.base.recentScore),
          ),
        );

        (await handler.restoreTypeSpecific(
          base: selected.base,
          payload: selected.payload,
        )).getOrThrow();

        (await customFieldsRestoreService.restoreCustomFieldsForSnapshot(
          itemId: selected.base.itemId,
          snapshotHistoryId: selected.base.historyId,
        )).getOrThrow();

        (await tagsRestoreService.restoreTagsForSnapshot(
          itemId: selected.base.itemId,
          snapshotHistoryId: selected.base.historyId,
        )).getOrThrow();

        (await itemLinksRestoreService.restoreLinksForSnapshot(
          itemId: selected.base.itemId,
          snapshotHistoryId: selected.base.historyId,
        )).getOrThrow();

        (await eventHistoryRepository.writeEvent(
          itemId: selected.base.itemId,
          type: selected.base.type,
          action: VaultEventHistoryAction.restored,
          name: selected.base.name,
          snapshotHistoryId: beforeRestoreSnapshotId,
        )).getOrThrow();

        return unit;
      });
    }, (e, st) => e is DBCoreError ? e : mapDbException(e, st));
  }
}
