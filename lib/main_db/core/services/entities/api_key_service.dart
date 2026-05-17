import 'package:hoplixi/main_db/core/errors/db_error.dart';
import 'package:hoplixi/main_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/main_db/core/errors/db_result.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/repositories/base/api_key_repository.dart';
import 'package:hoplixi/main_db/core/services/history/facades/vault_history_service.dart';
import 'package:hoplixi/main_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/main_db/core/services/vault_items_state_service.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:hoplixi/main_db/core/validators/api_key_validator.dart';
import 'package:result_dart/result_dart.dart';

import '../../main_store.dart';

class ApiKeyService {
  ApiKeyService({
    required this.db,
    required this.repository,
    required this.relationsService,
    required this.historyService,
    required this.vaultItemsStateService,
  });

  final MainStore db;
  final ApiKeyRepository repository;
  final VaultItemRelationsService relationsService;
  final VaultHistoryService historyService;
  final VaultItemsStateService vaultItemsStateService;

  Future<DbResult<String>> create(CreateApiKeyDto dto) async {
    final validationError = validateCreateApiKey(dto);
    if (validationError != null) return Failure(validationError);

    try {
      return await db.transaction(() async {
        // 1. Создаем запись в репозитории
        final itemId = await repository.create(dto);

        // 2. Привязываем теги
        if (dto.tagIds.isNotEmpty) {
          final res = await relationsService.replaceTags(
            itemId: itemId,
            tagIds: dto.tagIds,
          );
          if (res.isError()) throw res.exceptionOrNull()!;
        }

        // 3. Получаем созданное состояние для snapshot
        final createdView = await repository.getViewById(itemId);
        if (createdView == null) {
          throw DBCoreError.notFound(
            entity: 'apiKey',
            id: itemId,
            message: 'Failed to retrieve created ApiKey: $itemId',
          );
        }

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
          type: VaultItemType.apiKey,
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

  Future<DbResult<Unit>> update(PatchApiKeyDto dto) async {
    final validationError = validatePatchApiKey(dto);
    if (validationError != null) return Failure(validationError);

    try {
      return await db.transaction(() async {
        final itemId = dto.item.itemId;

        // 1. Получаем старое состояние для snapshot
        final oldView = await repository.getViewById(itemId);
        if (oldView == null) {
          throw DBCoreError.notFound(
            entity: 'apiKey',
            id: itemId,
            message: 'ApiKey not found for update: $itemId',
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
        await repository.update(dto);

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
          type: VaultItemType.apiKey,
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
      type: VaultItemType.apiKey,
    );
  }

  Future<DbResult<Unit>> recover(String itemId) {
    return vaultItemsStateService.recover(
      itemId: itemId,
      type: VaultItemType.apiKey,
    );
  }

  Future<DbResult<Unit>> archive(String itemId) {
    return vaultItemsStateService.archive(
      itemId: itemId,
      type: VaultItemType.apiKey,
    );
  }

  Future<DbResult<Unit>> restoreArchived(String itemId) {
    return vaultItemsStateService.restoreArchived(
      itemId: itemId,
      type: VaultItemType.apiKey,
    );
  }

  Future<DbResult<Unit>> setFavorite(String itemId, bool value) {
    return vaultItemsStateService.setFavorite(
      itemId: itemId,
      type: VaultItemType.apiKey,
      value: value,
    );
  }

  Future<DbResult<Unit>> setPinned(String itemId, bool value) {
    return vaultItemsStateService.setPinned(
      itemId: itemId,
      type: VaultItemType.apiKey,
      value: value,
    );
  }
}
