import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/services/history/custom_fields/custom_fields_restore_service.dart';
import 'package:hoplixi/main_db/core/services/history/item_links_restore_service.dart';
import 'package:hoplixi/main_db/core/services/history/tags_restore_service.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_exception_mapper.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/vault_items/vault_events_history.dart';
import '../../vault_typed_view_resolver.dart';
import '../restore_handlers/restore_handlers.dart';
import '../vault_event_history_service.dart';
import '../vault_history_normalized_loader.dart';
import '../policy/vault_history_restore_policy_service.dart';
import '../vault_snapshot_writer.dart';

class VaultHistoryRestoreService {
  VaultHistoryRestoreService({
    required this.loader,
    required this.policy,
    required this.db,
    required this.vaultItemsDao,
    required this.restoreHandlerRegistry,
    required this.customFieldsRestoreService,
    required this.tagsRestoreService,
    required this.itemLinksRestoreService,
    required this.viewResolver,
    required this.snapshotWriter,
    required this.eventHistoryService,
  });

  final VaultHistoryNormalizedLoader loader;
  final VaultHistoryRestorePolicyService policy;
  final MainStore db;
  final VaultItemsDao vaultItemsDao;
  final VaultHistoryRestoreHandlerRegistry restoreHandlerRegistry;
  final CustomFieldsRestoreService customFieldsRestoreService;
  final TagsRestoreService tagsRestoreService;
  final ItemLinksRestoreService itemLinksRestoreService;
  final VaultTypedViewResolver viewResolver;
  final VaultSnapshotWriter snapshotWriter;
  final VaultEventHistoryService eventHistoryService;

  Future<DbResult<Unit>> restoreRevision({
    required String historyId,
    bool recreate = false,
  }) async {
    try {
      final selected = await loader.loadHistorySnapshot(historyId);
      if (selected == null) {
        return Failure(
          DBCoreError.notFound(entity: 'HistorySnapshot', id: historyId),
        );
      }

      if (!policy.isRestorable(selected)) {
        return const Failure(
          DBCoreError.validation(
            code: 'history.restore.not_restorable',
            message: 'Эта ревизия не может быть восстановлена',
          ),
        );
      }

      final handler = restoreHandlerRegistry.get(selected.base.type);
      if (handler == null) {
        return Failure(
          DBCoreError.validation(
            code: 'history.restore.unsupported_type',
            message:
                'Восстановление для типа ${selected.base.type.name} не поддерживается',
          ),
        );
      }

      return await db.transaction(() async {
        String? beforeRestoreSnapshotId;

        final currentView = await viewResolver.getView(
          itemId: selected.base.itemId,
          type: selected.base.type,
        );

        if (currentView == null && !recreate) {
          return Failure(
            DBCoreError.notFound(
              entity: selected.base.type.name,
              id: selected.base.itemId,
              message:
                  'Live item not found. Use recreate=true to restore deleted physical item.',
            ),
          );
        }

        if (currentView != null) {
          if (currentView is! VaultEntityViewDto) {
            throw _InternalRestoreFailure(
              DBCoreError.conflict(
                code: 'history.restore.invalid_current_view',
                message: 'Current view does not implement VaultEntityViewDto',
                entity: selected.base.type.name,
              ),
            );
          }

          final snapshotRes = await snapshotWriter.writeSnapshot(
            view: currentView,
            action: VaultEventHistoryAction.restored,
            includeSecrets: true,
            includeRelations: true,
          );

          if (snapshotRes.isError()) {
            throw _InternalRestoreFailure(snapshotRes.exceptionOrNull()!);
          }

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

        final typeRes = await handler.restoreTypeSpecific(
          base: selected.base,
          payload: selected.payload,
        );

        if (typeRes.isError()) {
          throw _InternalRestoreFailure(typeRes.exceptionOrNull()!);
        }

        final customFieldsRes = await customFieldsRestoreService
            .restoreCustomFieldsForSnapshot(
              itemId: selected.base.itemId,
              snapshotHistoryId: selected.base.historyId,
            );
        if (customFieldsRes.isError()) {
          throw _InternalRestoreFailure(customFieldsRes.exceptionOrNull()!);
        }

        final tagsRes = await tagsRestoreService.restoreTagsForSnapshot(
          itemId: selected.base.itemId,
          snapshotHistoryId: selected.base.historyId,
        );
        if (tagsRes.isError()) {
          throw _InternalRestoreFailure(tagsRes.exceptionOrNull()!);
        }

        final linksRes = await itemLinksRestoreService.restoreLinksForSnapshot(
          itemId: selected.base.itemId,
          snapshotHistoryId: selected.base.historyId,
        );
        if (linksRes.isError()) {
          throw _InternalRestoreFailure(linksRes.exceptionOrNull()!);
        }

        final eventRes = await eventHistoryService.writeEvent(
          itemId: selected.base.itemId,
          type: selected.base.type,
          action: VaultEventHistoryAction.restored,
          name: selected.base.name,
          categoryId: selected.base.categoryId,
          iconRefId: selected.base.iconRefId,
          snapshotHistoryId: beforeRestoreSnapshotId,
        );

        if (eventRes.isError()) {
          throw _InternalRestoreFailure(eventRes.exceptionOrNull()!);
        }

        return const Success(unit);
      });
    } on _InternalRestoreFailure catch (e) {
      return Failure(e.error);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }
}

class _InternalRestoreFailure implements Exception {
  _InternalRestoreFailure(this.error);
  final DBCoreError error;
}
