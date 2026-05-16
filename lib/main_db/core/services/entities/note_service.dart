import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/repositories/base/note_repository.dart';
import 'package:hoplixi/main_db/core/services/history/vault_history_service.dart';
import 'package:hoplixi/main_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';

import '../../main_store.dart';

class NoteService {
  NoteService({
    required this.db,
    required this.repository,
    required this.relationsService,
    required this.historyService,
  });

  final MainStore db;
  final NoteRepository repository;
  final VaultItemRelationsService relationsService;
  final VaultHistoryService historyService;

  Future<String> create({
    required CreateNoteDto dto,
    List<String> tagIds = const [],
  }) async {
    return await db.transaction(() async {
      final itemId = await repository.create(dto);

      if (tagIds.isNotEmpty) {
        await relationsService.replaceTags(itemId: itemId, tagIds: tagIds);
      }

      final createdView = await repository.getViewById(itemId);
      if (createdView == null) {
        throw Exception('Failed to retrieve created Note: $itemId');
      }

      final snapshotId = await historyService.snapshotAfterCreate(
        type: VaultItemType.note,
        createdView: createdView,
        action: VaultEventHistoryAction.created,
      );

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.note,
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
    required PatchNoteDto dto,
    List<String>? tagIds,
  }) async {
    await db.transaction(() async {
      final itemId = dto.item.itemId;

      final oldView = await repository.getViewById(itemId);
      if (oldView == null) {
        throw Exception('Note not found for update: $itemId');
      }

      final snapshotId = await historyService.snapshotBeforeUpdate(
        type: VaultItemType.note,
        oldView: oldView,
        action: VaultEventHistoryAction.updated,
      );

      await repository.update(dto);

      if (tagIds != null) {
        await relationsService.replaceTags(itemId: itemId, tagIds: tagIds);
      }

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.note,
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
        type: VaultItemType.note,
        oldView: oldView,
        action: VaultEventHistoryAction.deleted,
      );

      await db.vaultItemsDao.softDeleteItem(itemId, DateTime.now());

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.note,
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
        type: VaultItemType.note,
        oldView: oldView,
        action: VaultEventHistoryAction.recovered,
      );

      await db.vaultItemsDao.recoverDeletedItem(itemId, DateTime.now());

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.note,
        action: VaultEventHistoryAction.recovered,
        name: oldView.item.name,
        snapshotHistoryId: snapshotId,
      );
    });
  }
}
