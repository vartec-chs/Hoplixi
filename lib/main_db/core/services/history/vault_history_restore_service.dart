import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/services/history/custom_fields_restore_service.dart';
import 'package:hoplixi/main_db/core/services/history/item_links_restore_service.dart';
import 'package:hoplixi/main_db/core/services/history/tags_restore_service.dart';
import 'package:result_dart/result_dart.dart';

import '../../daos/daos.dart';
import '../../errors/db_error.dart';
import '../../errors/db_exception_mapper.dart';
import '../../errors/db_result.dart';
import '../../tables/tables.dart';

import 'restore_handlers/restore_handlers.dart';
import 'vault_history_normalized_loader.dart';
import 'vault_history_restore_policy_service.dart';

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
  });

  final VaultHistoryNormalizedLoader loader;
  final VaultHistoryRestorePolicyService policy;
  final MainStore db;
  final VaultItemsDao vaultItemsDao;
  final VaultHistoryRestoreHandlerRegistry restoreHandlerRegistry;
  final CustomFieldsRestoreService customFieldsRestoreService;
  final TagsRestoreService tagsRestoreService;
  final ItemLinksRestoreService itemLinksRestoreService;

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
        await vaultItemsDao.upsertVaultItem(
          VaultItemsCompanion(
            id: Value(selected.base.itemId),
            type: Value(selected.base.type),
            name: Value(selected.base.name),
            description: Value(selected.base.description),
            categoryId: Value(selected.base.categoryId),
            iconRefId: Value(selected.base.iconRefId),
            isFavorite: Value(selected.base.isFavorite),
            isArchived: Value(selected.base.isArchived),
            isPinned: Value(selected.base.isPinned),
            isDeleted: Value(false), // Always restore as active
            createdAt: Value(selected.base.createdAt),
            modifiedAt: Value(DateTime.now()), // Updated modification time
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
