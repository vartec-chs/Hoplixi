// TODO(db-error): migrate service to DbResult<..., DbError>.
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/repositories/base/document_repository.dart';
import 'package:hoplixi/main_db/core/services/history/vault_history_service.dart';
import 'package:hoplixi/main_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';

import '../../main_store.dart';

class DocumentService {
  DocumentService({
    required this.db,
    required this.repository,
    required this.relationsService,
    required this.historyService,
  });

  final MainStore db;
  final DocumentRepository repository;
  final VaultItemRelationsService relationsService;
  final VaultHistoryService historyService;

  Future<String> create(CreateDocumentDto dto) async {
    return await db.transaction(() async {
      final itemId = await repository.create(dto);

      if (dto.tagIds.isNotEmpty) {
        await relationsService.replaceTags(itemId: itemId, tagIds: dto.tagIds);
      }

      final createdView = await repository.getViewById(itemId);
      if (createdView == null) {
        throw Exception('Failed to retrieve created Document: $itemId');
      }

      // Note: Documents use versions, but we still write an event for the document item itself.
      // We might not write a standard entity snapshot if it's handled by versions, 
      // but the instruction says "пишет event history".
      
      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.document,
        action: VaultEventHistoryAction.created,
        name: createdView.item.name,
        categoryId: createdView.item.categoryId,
        iconRefId: createdView.item.iconRefId,
      );

      return itemId;
    });
  }

  Future<void> update(PatchDocumentDto dto) async {
    await db.transaction(() async {
      final itemId = dto.item.itemId;

      final oldView = await repository.getViewById(itemId);
      if (oldView == null) {
        throw Exception('Document not found for update: $itemId');
      }

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
        type: VaultItemType.document,
        action: VaultEventHistoryAction.updated,
        name: dto.item.name.valueOrNull ?? oldView.item.name,
        categoryId: dto.item.categoryId.valueOrNull ?? oldView.item.categoryId,
        iconRefId: dto.item.iconRefId.valueOrNull ?? oldView.item.iconRefId,
      );
    });
  }

  Future<void> softDelete(String itemId) async {
    await db.transaction(() async {
      final oldView = await repository.getViewById(itemId);
      if (oldView == null) return;

      await db.vaultItemsDao.softDeleteItem(itemId, DateTime.now());

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.document,
        action: VaultEventHistoryAction.deleted,
        name: oldView.item.name,
      );
    });
  }

  Future<void> recover(String itemId) async {
    await db.transaction(() async {
      final oldView = await repository.getViewById(itemId);
      if (oldView == null) return;

      await db.vaultItemsDao.recoverDeletedItem(itemId, DateTime.now());

      await historyService.writeEvent(
        itemId: itemId,
        type: VaultItemType.document,
        action: VaultEventHistoryAction.recovered,
        name: oldView.item.name,
      );
    });
  }
}

