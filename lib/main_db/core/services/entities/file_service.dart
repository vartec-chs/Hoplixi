// TODO(db-error): migrate service to DbResult<..., DbError>.
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/repositories/base/file_repository.dart';
import 'package:hoplixi/main_db/core/services/history/vault_history_service.dart';
import 'package:hoplixi/main_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';

import '../../main_store.dart';

class FileService {
  FileService({
    required this.db,
    required this.repository,
    required this.relationsService,
    required this.historyService,
  });

  final MainStore db;
  final FileRepository repository;
  final VaultItemRelationsService relationsService;
  final VaultHistoryService historyService;

  Future<String> create(CreateFileDto dto) async {
    return await db.transaction(() async {
      final itemId = await repository.create(dto);

      if (dto.tagIds.isNotEmpty) {
        await relationsService.replaceTags(itemId: itemId, tagIds: dto.tagIds);
      }

      final createdView = await repository.getViewById(itemId);
      if (createdView == null) {
        throw Exception('Failed to retrieve created File: $itemId');
      }

      // Snapshot for File
      final snapshotId = await historyService.snapshotAfterCreate(
        type: VaultItemType.file,
        createdView: createdView,
        action: VaultEventHistoryAction.created,
      );

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.file,
        action: VaultEventHistoryAction.created,
        name: createdView.item.name,
        categoryId: createdView.item.categoryId,
        iconRefId: createdView.item.iconRefId,
        snapshotHistoryId: snapshotId?.getOrNull(),
      );

      return itemId;
    });
  }

  Future<void> update(PatchFileDto dto) async {
    await db.transaction(() async {
      final itemId = dto.item.itemId;

      final oldView = await repository.getViewById(itemId);
      if (oldView == null) {
        throw Exception('File not found for update: $itemId');
      }

      final snapshotId = await historyService.snapshotBeforeUpdate(
        type: VaultItemType.file,
        oldView: oldView,
        action: VaultEventHistoryAction.updated,
      );

      await repository.update(dto);

      final tagsUpdate = dto.tags;
      if (tagsUpdate is FieldUpdateSet<List<String>>) {
        await relationsService.replaceTags(
          itemId: itemId,
          tagIds: tagsUpdate.value ?? const [],
        );
      }

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.file,
        action: VaultEventHistoryAction.updated,
        name: dto.item.name.valueOrNull ?? oldView.item.name,
        categoryId: dto.item.categoryId.valueOrNull ?? oldView.item.categoryId,
        iconRefId: dto.item.iconRefId.valueOrNull ?? oldView.item.iconRefId,
        snapshotHistoryId: snapshotId?.getOrNull(),
      );
    });
  }

  Future<void> softDelete(String itemId) async {
    await db.transaction(() async {
      final oldView = await repository.getViewById(itemId);
      if (oldView == null) return;

      final snapshotId = await historyService.snapshotBeforeUpdate(
        type: VaultItemType.file,
        oldView: oldView,
        action: VaultEventHistoryAction.deleted,
      );

      await db.vaultItemsDao.softDeleteItem(itemId, DateTime.now());

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.file,
        action: VaultEventHistoryAction.deleted,
        name: oldView.item.name,
        snapshotHistoryId: snapshotId?.getOrNull(),
      );
    });
  }

  Future<void> recover(String itemId) async {
    await db.transaction(() async {
      final oldView = await repository.getViewById(itemId);
      if (oldView == null) return;

      final snapshotId = await historyService.snapshotBeforeUpdate(
        type: VaultItemType.file,
        oldView: oldView,
        action: VaultEventHistoryAction.recovered,
      );

      await db.vaultItemsDao.recoverDeletedItem(itemId, DateTime.now());

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.file,
        action: VaultEventHistoryAction.recovered,
        name: oldView.item.name,
        snapshotHistoryId: snapshotId?.getOrNull(),
      );
    });
  }
}


