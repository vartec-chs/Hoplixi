import 'package:hoplixi/main_db/core/errors/db_error.dart';
import 'package:hoplixi/main_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/main_db/core/errors/db_result.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/services/history/vault_history_service.dart';
import 'package:hoplixi/main_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/main_db/core/services/vault_typed_view_resolver.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:result_dart/result_dart.dart';

class _InternalDbFailure implements Exception {
  const _InternalDbFailure(this.error);
  final DbError error;
}

class VaultItemMutationService {
  VaultItemMutationService({
    required this.db,
    required this.viewResolver,
    required this.relationsService,
    required this.historyService,
  });

  final MainStore db;
  final VaultTypedViewResolver viewResolver;
  final VaultItemRelationsService relationsService;
  final VaultHistoryService historyService;

  Future<DbResult<Unit>> replaceItemTags({
    required String itemId,
    required VaultItemType type,
    required List<String> tagIds,
  }) async {
    try {
      await db.transaction(() async {
        // 1. Получаем старое состояние для snapshot
        final untypedOldView = await viewResolver.getView(
          itemId: itemId,
          type: type,
        );
        if (untypedOldView == null) {
          throw _InternalDbFailure(DbError.notFound(
            entity: 'vaultItem',
            id: itemId,
            message: 'Vault item not found: $itemId',
          ));
        }

        final VaultEntityViewDto oldView = untypedOldView as VaultEntityViewDto;

        // 2. Пишем snapshot before update
        final snapshotRes = await historyService.snapshotBeforeUpdate(
          type: type,
          oldView: oldView,
          action: VaultEventHistoryAction.updated,
        );
        if (snapshotRes != null && snapshotRes.isError()) {
          throw _InternalDbFailure(snapshotRes.exceptionOrNull()!);
        }

        // 3. Заменяем теги
        final res = await relationsService.replaceTags(
          itemId: itemId,
          tagIds: tagIds,
        );
        if (res.isError()) throw _InternalDbFailure(res.exceptionOrNull()!);

        // 4. Пишем event updated
        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: type,
          action: VaultEventHistoryAction.updated,
          snapshotHistoryId: snapshotRes?.getOrNull(),
        );
        if (eventRes.isError()) throw _InternalDbFailure(eventRes.exceptionOrNull()!);
      });
      return const Success(unit);
    } on _InternalDbFailure catch (e) {
      return Failure(e.error);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<DbResult<Unit>> changeItemCategory({
    required String itemId,
    required VaultItemType type,
    required String? categoryId,
  }) async {
    try {
      await db.transaction(() async {
        // 1. Получаем старое состояние для snapshot
        final untypedOldView = await viewResolver.getView(
          itemId: itemId,
          type: type,
        );
        if (untypedOldView == null) {
          throw _InternalDbFailure(DbError.notFound(
            entity: 'vaultItem',
            id: itemId,
            message: 'Vault item not found: $itemId',
          ));
        }

        final VaultEntityViewDto oldView = untypedOldView as VaultEntityViewDto;

        // 2. Пишем snapshot before update
        final snapshotRes = await historyService.snapshotBeforeUpdate(
          type: type,
          oldView: oldView,
          action: VaultEventHistoryAction.updated,
        );
        if (snapshotRes != null && snapshotRes.isError()) {
          throw _InternalDbFailure(snapshotRes.exceptionOrNull()!);
        }

        // 3. Меняем категорию
        final res = await relationsService.changeCategory(
          itemId: itemId,
          categoryId: categoryId,
        );
        if (res.isError()) throw _InternalDbFailure(res.exceptionOrNull()!);

        // 4. Пишем event updated
        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: type,
          action: VaultEventHistoryAction.updated,
          categoryId: categoryId,
          snapshotHistoryId: snapshotRes?.getOrNull(),
        );
        if (eventRes.isError()) throw _InternalDbFailure(eventRes.exceptionOrNull()!);
      });
      return const Success(unit);
    } on _InternalDbFailure catch (e) {
      return Failure(e.error);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }
}
