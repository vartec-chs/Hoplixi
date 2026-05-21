import 'package:hoplixi/vault_db/core/errors/db_error.dart';
import 'package:hoplixi/vault_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/repositories/base/identity_repository.dart';
import 'package:hoplixi/vault_db/core/services/entities/base_vault_entity_service.dart';
import 'package:hoplixi/vault_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/vault_db/core/tables/vault_items/vault_items.dart';
import 'package:hoplixi/vault_db/core/validators/identity_validator.dart';
import 'package:result_dart/result_dart.dart';

class IdentityService extends BaseVaultEntityService<IdentityRepository> {
  IdentityService({required super.deps, required super.repository});

  Future<DbResult<String>> create(CreateIdentityDto dto) async {
    final validationError = validateCreateIdentity(dto);
    if (validationError != null) return Failure(validationError);

    try {
      return await db.transaction(() async {
        // 1. Создаем запись в репозитории
        final itemId = (await repository.create(dto)).getOrThrow();

        // 2. Привязываем теги
        if (dto.tagIds.isNotEmpty) {
          final res = await relationsService.replaceTags(
            itemId: itemId,
            tagIds: dto.tagIds,
          );
          if (res.isError()) throw res.exceptionOrNull()!;
        }

        // 3. Получаем созданное состояние для snapshot
        final createdViewResult = await repository.getViewById(itemId);
        final createdView = createdViewResult.getOrThrow().fold(
          (view) => view,
          () => throw DBCoreError.notFound(
            entity: 'identity',
            id: itemId,
            message: 'Failed to retrieve created Identity: $itemId',
          ),
        );

        // 4. Пишем snapshot created (After create)
        final snapshotRes = await historyService.snapshotAfterCreate(
          createdView: createdView,
          action: VaultEventHistoryAction.created,
        );
        if (snapshotRes != null && snapshotRes.isError()) {
          throw snapshotRes.exceptionOrNull()!;
        }

        // 5. Пишем event created
        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.identity,
          action: VaultEventHistoryAction.created,
          name: createdView.item.name,
          snapshotHistoryId: snapshotRes?.getOrNull(),
        );
        if (eventRes.isError()) throw eventRes.exceptionOrNull()!;

        return Success(itemId);
      });
    } on DBCoreError catch (e) {
      return Failure(e);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<DbResult<Unit>> update(PatchIdentityDto dto) async {
    final validationError = validatePatchIdentity(dto);
    if (validationError != null) return Failure(validationError);

    try {
      return await db.transaction(() async {
        final itemId = dto.item.itemId;

        // 1. Получаем старое состояние для snapshot
        final oldView = (await repository.getViewById(itemId)).getOrThrow().getOrNull();
        if (oldView == null) {
          throw DBCoreError.notFound(
            entity: 'identity',
            id: itemId,
            message: 'Identity not found for update: $itemId',
          );
        }

        // 2. Пишем snapshot before update
        final snapshotRes = await historyService.snapshotBeforeUpdate(
          oldView: oldView,
          action: VaultEventHistoryAction.updated,
        );
        if (snapshotRes != null && snapshotRes.isError()) {
          throw snapshotRes.exceptionOrNull()!;
        }

        // 3. Обновляем данные в репозитории
        (await repository.update(dto)).getOrThrow();

        // 4. Обновляем теги если переданы
        final tagsUpdate = dto.tags;
        if (tagsUpdate is FieldUpdateSet<List<String>>) {
          final res = await relationsService.replaceTags(
            itemId: itemId,
            tagIds: tagsUpdate.value ?? const [],
          );
          if (res.isError()) throw res.exceptionOrNull()!;
        }

        // 5. Пишем event updated
        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.identity,
          action: VaultEventHistoryAction.updated,
          name: dto.item.name.valueOrNull ?? oldView.item.name,
          snapshotHistoryId: snapshotRes?.getOrNull(),
        );
        if (eventRes.isError()) throw eventRes.exceptionOrNull()!;

        return const Success(unit);
      });
    } on DBCoreError catch (e) {
      return Failure(e);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<DbResult<Unit>> softDelete(String itemId) {
    return vaultItemsStateService.softDelete(
      itemId: itemId,
      type: VaultItemType.identity,
    );
  }

  Future<DbResult<Unit>> recover(String itemId) {
    return vaultItemsStateService.recover(
      itemId: itemId,
      type: VaultItemType.identity,
    );
  }

  Future<DbResult<Unit>> archive(String itemId) {
    return vaultItemsStateService.archive(
      itemId: itemId,
      type: VaultItemType.identity,
    );
  }

  Future<DbResult<Unit>> restoreArchived(String itemId) {
    return vaultItemsStateService.restoreArchived(
      itemId: itemId,
      type: VaultItemType.identity,
    );
  }

  Future<DbResult<Unit>> setFavorite(String itemId, bool value) {
    return vaultItemsStateService.setFavorite(
      itemId: itemId,
      type: VaultItemType.identity,
      value: value,
    );
  }

  Future<DbResult<Unit>> setPinned(String itemId, bool value) {
    return vaultItemsStateService.setPinned(
      itemId: itemId,
      type: VaultItemType.identity,
      value: value,
    );
  }
}
