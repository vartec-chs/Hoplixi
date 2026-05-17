import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/errors/db_error.dart';
import 'package:hoplixi/main_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/main_db/core/errors/db_result.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/services/history/vault_history_service.dart';
import 'package:hoplixi/main_db/core/services/vault_typed_view_resolver.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:result_dart/result_dart.dart';

import '../main_store.dart';

/// Сервис для изменения общих состояний записей хранилища (vault_items).
class VaultItemsStateService {
  VaultItemsStateService({
    required this.db,
    required this.viewResolver,
    required this.historyService,
  });

  final MainStore db;
  final VaultTypedViewResolver viewResolver;
  final VaultHistoryService historyService;

  Future<DbResult<Unit>> softDelete({
    required String itemId,
    required VaultItemType type,
  }) {
    return _mutateState(
      itemId: itemId,
      type: type,
      action: VaultEventHistoryAction.deleted,
      mutate: (now) => db.vaultItemsDao.softDeleteItem(itemId, now),
    );
  }

  Future<DbResult<Unit>> recover({
    required String itemId,
    required VaultItemType type,
  }) {
    return _mutateState(
      itemId: itemId,
      type: type,
      action: VaultEventHistoryAction.recovered,
      mutate: (now) => db.vaultItemsDao.recoverDeletedItem(itemId, now),
    );
  }

  Future<DbResult<Unit>> archive({
    required String itemId,
    required VaultItemType type,
  }) {
    return _mutateState(
      itemId: itemId,
      type: type,
      action: VaultEventHistoryAction.archived,
      mutate: (now) => db.vaultItemsDao.archiveItem(itemId, now),
    );
  }

  Future<DbResult<Unit>> restoreArchived({
    required String itemId,
    required VaultItemType type,
  }) {
    return _mutateState(
      itemId: itemId,
      type: type,
      action: VaultEventHistoryAction.restored,
      mutate: (now) => db.vaultItemsDao.restoreArchivedItem(itemId, now),
    );
  }

  Future<DbResult<Unit>> setFavorite({
    required String itemId,
    required VaultItemType type,
    required bool value,
  }) {
    return _mutateState(
      itemId: itemId,
      type: type,
      action: value
          ? VaultEventHistoryAction.favorited
          : VaultEventHistoryAction.unfavorited,
      mutate: (now) => db.vaultItemsDao.updateVaultItemById(
        itemId,
        VaultItemsCompanion(isFavorite: Value(value), modifiedAt: Value(now)),
      ),
    );
  }

  Future<DbResult<Unit>> setPinned({
    required String itemId,
    required VaultItemType type,
    required bool value,
  }) {
    return _mutateState(
      itemId: itemId,
      type: type,
      action: value
          ? VaultEventHistoryAction.pinned
          : VaultEventHistoryAction.unpinned,
      mutate: (now) => db.vaultItemsDao.updateVaultItemById(
        itemId,
        VaultItemsCompanion(isPinned: Value(value), modifiedAt: Value(now)),
      ),
    );
  }

  Future<DbResult<Unit>> _mutateState({
    required String itemId,
    required VaultItemType type,
    required VaultEventHistoryAction action,
    required Future<void> Function(DateTime now) mutate,
  }) async {
    try {
      return await db.transaction(() async {
        final Object? untypedOldView = await viewResolver.getView(
          itemId: itemId,
          type: type,
        );

        if (untypedOldView == null) {
          throw DBCoreError.notFound(
            entity: 'vaultItem',
            id: itemId,
            message: 'Запись не найдена',
          );
        }

        final VaultEntityViewDto oldView = untypedOldView as VaultEntityViewDto;

        final snapshotRes = await historyService.snapshotBeforeUpdate(
          oldView: oldView,
          action: action,
        );
        if (snapshotRes != null && snapshotRes.isError()) {
          throw snapshotRes.exceptionOrNull()!;
        }

        final now = DateTime.now();
        await mutate(now);

        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: type,
          action: action,
          name: oldView.item.name,
          categoryId: oldView.item.categoryId,
          iconRefId: oldView.item.iconRefId,
          snapshotHistoryId: snapshotRes?.getOrNull(),
        );
        if (eventRes.isError()) {
          throw eventRes.exceptionOrNull()!;
        }

        return const Success(unit);
      });
    } on DBCoreError catch (e) {
      return Failure(e);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }
}
