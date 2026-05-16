import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/repositories/base/api_key_repository.dart';
import 'package:hoplixi/main_db/core/services/history/vault_history_service.dart';
import 'package:hoplixi/main_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';

import '../../main_store.dart';

class ApiKeyService {
  ApiKeyService({
    required this.db,
    required this.repository,
    required this.relationsService,
    required this.historyService,
  });

  final MainStore db;
  final ApiKeyRepository repository;
  final VaultItemRelationsService relationsService;
  final VaultHistoryService historyService;

  Future<String> create({
    required CreateApiKeyDto dto,
    List<String> tagIds = const [],
  }) async {
    return await db.transaction(() async {
      // 1. Создаем запись в репозитории
      final itemId = await repository.create(dto);

      // 2. Привязываем теги
      if (tagIds.isNotEmpty) {
        await relationsService.replaceTags(itemId: itemId, tagIds: tagIds);
      }

      // 3. Получаем созданное состояние для snapshot
      final createdView = await repository.getViewById(itemId);
      if (createdView == null) {
        throw Exception('Failed to retrieve created ApiKey: $itemId');
      }

      // 4. Пишем snapshot created (After create)
      final snapshotId = await historyService.snapshotAfterCreate(
        type: VaultItemType.apiKey,
        createdView: createdView,
        action: VaultEventHistoryAction.created,
      );

      // 5. Пишем event created
      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.apiKey,
        action: VaultEventHistoryAction.created,
        name: createdView.item.name,
        categoryId: createdView.item.categoryId,
        iconRefId: createdView.item.iconRefId,
        snapshotHistoryId: snapshotId,
      );

      return itemId;
    });
  }

  Future<void> update({
    required PatchApiKeyDto dto,
    List<String>? tagIds,
  }) async {
    await db.transaction(() async {
      final itemId = dto.item.itemId;

      // 1. Получаем старое состояние для snapshot
      final oldView = await repository.getViewById(itemId);
      if (oldView == null) {
        throw Exception('ApiKey not found for update: $itemId');
      }

      // 2. Пишем snapshot before update
      final snapshotId = await historyService.snapshotBeforeUpdate(
        type: VaultItemType.apiKey,
        oldView: oldView,
        action: VaultEventHistoryAction.updated,
      );

      // 3. Обновляем данные в репозитории
      await repository.update(dto);

      // 4. Обновляем теги если переданы
      if (tagIds != null) {
        await relationsService.replaceTags(itemId: itemId, tagIds: tagIds);
      }

      // 5. Пишем event updated
      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.apiKey,
        action: VaultEventHistoryAction.updated,
        name: dto.item.name.valueOrNull ?? oldView.item.name,
        categoryId: dto.item.categoryId.valueOrNull ?? oldView.item.categoryId,
        iconRefId: dto.item.iconRefId.valueOrNull ?? oldView.item.iconRefId,
        snapshotHistoryId: snapshotId,
      );
    });
  }

  Future<void> softDelete(String itemId) async {
    await db.transaction(() async {
      final oldView = await repository.getViewById(itemId);
      if (oldView == null) return;

      final snapshotId = await historyService.snapshotBeforeUpdate(
        type: VaultItemType.apiKey,
        oldView: oldView,
        action: VaultEventHistoryAction.deleted,
      );

      await db.vaultItemsDao.softDeleteItem(itemId, DateTime.now());

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.apiKey,
        action: VaultEventHistoryAction.deleted,
        name: oldView.item.name,
        snapshotHistoryId: snapshotId,
      );
    });
  }

  Future<void> recover(String itemId) async {
    await db.transaction(() async {
      final oldView = await repository.getViewById(itemId);
      if (oldView == null) return;

      final snapshotId = await historyService.snapshotBeforeUpdate(
        type: VaultItemType.apiKey,
        oldView: oldView,
        action: VaultEventHistoryAction.recovered,
      );

      await db.vaultItemsDao.recoverDeletedItem(itemId, DateTime.now());

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.apiKey,
        action: VaultEventHistoryAction.recovered,
        name: oldView.item.name,
        snapshotHistoryId: snapshotId,
      );
    });
  }

  Future<void> archive(String itemId) async {
    await db.transaction(() async {
      final oldView = await repository.getViewById(itemId);
      if (oldView == null) return;

      final snapshotId = await historyService.snapshotBeforeUpdate(
        type: VaultItemType.apiKey,
        oldView: oldView,
        action: VaultEventHistoryAction.archived,
      );

      await db.vaultItemsDao.archiveItem(itemId, DateTime.now());

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.apiKey,
        action: VaultEventHistoryAction.archived,
        name: oldView.item.name,
        snapshotHistoryId: snapshotId,
      );
    });
  }

  Future<void> restoreArchived(String itemId) async {
    await db.transaction(() async {
      final oldView = await repository.getViewById(itemId);
      if (oldView == null) return;

      final snapshotId = await historyService.snapshotBeforeUpdate(
        type: VaultItemType.apiKey,
        oldView: oldView,
        action: VaultEventHistoryAction.restored,
      );

      await db.vaultItemsDao.restoreArchivedItem(itemId, DateTime.now());

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.apiKey,
        action: VaultEventHistoryAction.restored,
        name: oldView.item.name,
        snapshotHistoryId: snapshotId,
      );
    });
  }
}
