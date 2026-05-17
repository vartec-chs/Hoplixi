import 'package:hoplixi/main_db/core/errors/db_error.dart';
import 'package:hoplixi/main_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/main_db/core/errors/db_result.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/repositories/base/file_repository.dart';
import 'package:hoplixi/main_db/core/services/history/vault_history_service.dart';
import 'package:hoplixi/main_db/core/services/vault_items_state_service.dart';
import 'package:hoplixi/main_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:hoplixi/main_db/core/validators/file_validator.dart';
import 'package:result_dart/result_dart.dart';

import '../../main_store.dart';

class FileService {
  FileService({
    required this.db,
    required this.repository,
    required this.relationsService,
    required this.historyService,
    required this.vaultItemsStateService,
  });

  final MainStore db;
  final FileRepository repository;
  final VaultItemRelationsService relationsService;
  final VaultHistoryService historyService;
  final VaultItemsStateService vaultItemsStateService;

  Future<DbResult<String>> create(CreateFileDto dto) async {
    final validationError = validateCreateFile(dto);
    if (validationError != null) return Failure(validationError);

    try {
      return await db.transaction(() async {
        final itemId = await repository.create(dto);

        if (dto.tagIds.isNotEmpty) {
          final res = await relationsService.replaceTags(
            itemId: itemId,
            tagIds: dto.tagIds,
          );
          if (res.isError()) throw res.exceptionOrNull()!;
        }

        final createdView = await repository.getViewById(itemId);
        if (createdView == null) {
          throw DBCoreError.notFound(
            entity: 'file',
            id: itemId,
            message: 'Failed to retrieve created File: $itemId',
          );
        }

        final snapshotRes = await historyService.snapshotAfterCreate(
          createdView: createdView,
          action: VaultEventHistoryAction.created,
        );
        if (snapshotRes != null && snapshotRes.isError())
          throw snapshotRes.exceptionOrNull()!;

        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.file,
          action: VaultEventHistoryAction.created,
          name: createdView.item.name,
          categoryId: createdView.item.categoryId,
          iconRefId: createdView.item.iconRefId,
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

  Future<DbResult<Unit>> update(PatchFileDto dto) async {
    final validationError = validatePatchFile(dto);
    if (validationError != null) return Failure(validationError);

    try {
      return await db.transaction(() async {
        final itemId = dto.item.itemId;

        final oldView = await repository.getViewById(itemId);
        if (oldView == null) {
          throw DBCoreError.notFound(
            entity: 'file',
            id: itemId,
            message: 'File not found for update: $itemId',
          );
        }

        final snapshotRes = await historyService.snapshotBeforeUpdate(
          oldView: oldView,
          action: VaultEventHistoryAction.updated,
        );
        if (snapshotRes != null && snapshotRes.isError())
          throw snapshotRes.exceptionOrNull()!;

        await repository.update(dto);

        final tagsUpdate = dto.tags;
        if (tagsUpdate is FieldUpdateSet<List<String>>) {
          final res = await relationsService.replaceTags(
            itemId: itemId,
            tagIds: tagsUpdate.value ?? const [],
          );
          if (res.isError()) throw res.exceptionOrNull()!;
        }

        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.file,
          action: VaultEventHistoryAction.updated,
          name: dto.item.name.valueOrNull ?? oldView.item.name,
          categoryId:
              dto.item.categoryId.valueOrNull ?? oldView.item.categoryId,
          iconRefId: dto.item.iconRefId.valueOrNull ?? oldView.item.iconRefId,
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
      type: VaultItemType.file,
    );
  }

  Future<DbResult<Unit>> recover(String itemId) {
    return vaultItemsStateService.recover(
      itemId: itemId,
      type: VaultItemType.file,
    );
  }

  Future<DbResult<Unit>> archive(String itemId) {
    return vaultItemsStateService.archive(
      itemId: itemId,
      type: VaultItemType.file,
    );
  }

  Future<DbResult<Unit>> restoreArchived(String itemId) {
    return vaultItemsStateService.restoreArchived(
      itemId: itemId,
      type: VaultItemType.file,
    );
  }

  Future<DbResult<Unit>> setFavorite(String itemId, bool value) {
    return vaultItemsStateService.setFavorite(
      itemId: itemId,
      type: VaultItemType.file,
      value: value,
    );
  }

  Future<DbResult<Unit>> setPinned(String itemId, bool value) {
    return vaultItemsStateService.setPinned(
      itemId: itemId,
      type: VaultItemType.file,
      value: value,
    );
  }
}
