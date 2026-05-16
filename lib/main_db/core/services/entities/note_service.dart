import 'package:hoplixi/main_db/core/errors/db_error.dart';
import 'package:hoplixi/main_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/main_db/core/errors/db_result.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/repositories/base/note_repository.dart';
import 'package:hoplixi/main_db/core/services/history/vault_history_service.dart';
import 'package:hoplixi/main_db/core/services/vault_items_state_service.dart';
import 'package:hoplixi/main_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:hoplixi/main_db/core/validators/note_validator.dart';
import 'package:result_dart/result_dart.dart';

import '../../main_store.dart';

class _InternalDbFailure implements Exception {
  const _InternalDbFailure(this.error);
  final DbError error;
}

class NoteService {
  NoteService({
    required this.db,
    required this.repository,
    required this.relationsService,
    required this.historyService,
    required this.vaultItemsStateService,
  });

  final MainStore db;
  final NoteRepository repository;
  final VaultItemRelationsService relationsService;
  final VaultHistoryService historyService;
  final VaultItemsStateService vaultItemsStateService;

  Future<DbResult<String>> create(CreateNoteDto dto) async {
    final validationError = validateCreateNote(dto);
    if (validationError != null) return Failure(validationError);

    try {
      return await db.transaction(() async {
        final itemId = await repository.create(dto);

        if (dto.tagIds.isNotEmpty) {
          final res = await relationsService.replaceTags(itemId: itemId, tagIds: dto.tagIds);
          if (res.isError()) throw _InternalDbFailure(res.exceptionOrNull()!);
        }

        final createdView = await repository.getViewById(itemId);
        if (createdView == null) {
          throw _InternalDbFailure(DbError.notFound(
            entity: 'note',
            id: itemId,
            message: 'Failed to retrieve created Note: $itemId',
          ));
        }

        final snapshotRes = await historyService.snapshotAfterCreate(
          type: VaultItemType.note,
          createdView: createdView,
          action: VaultEventHistoryAction.created,
        );
        if (snapshotRes != null && snapshotRes.isError()) throw _InternalDbFailure(snapshotRes.exceptionOrNull()!);

        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.note,
          action: VaultEventHistoryAction.created,
          name: createdView.item.name,
          categoryId: createdView.item.categoryId,
          iconRefId: createdView.item.iconRefId,
          snapshotHistoryId: snapshotRes?.getOrNull(),
        );
        if (eventRes.isError()) throw _InternalDbFailure(eventRes.exceptionOrNull()!);

        return Success(itemId);
      });
    } on _InternalDbFailure catch (e) {
      return Failure(e.error);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<DbResult<Unit>> update(PatchNoteDto dto) async {
    final validationError = validatePatchNote(dto);
    if (validationError != null) return Failure(validationError);

    try {
      return await db.transaction(() async {
        final itemId = dto.item.itemId;

        final oldView = await repository.getViewById(itemId);
        if (oldView == null) {
          throw _InternalDbFailure(DbError.notFound(
            entity: 'note',
            id: itemId,
            message: 'Note not found for update: $itemId',
          ));
        }

        final snapshotRes = await historyService.snapshotBeforeUpdate(
          type: VaultItemType.note,
          oldView: oldView,
          action: VaultEventHistoryAction.updated,
        );
        if (snapshotRes != null && snapshotRes.isError()) throw _InternalDbFailure(snapshotRes.exceptionOrNull()!);

        await repository.update(dto);

        final tagsUpdate = dto.tags;
        if (tagsUpdate is FieldUpdateSet<List<String>>) {
          final res = await relationsService.replaceTags(
            itemId: itemId,
            tagIds: tagsUpdate.value ?? const [],
          );
          if (res.isError()) throw _InternalDbFailure(res.exceptionOrNull()!);
        }

        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.note,
          action: VaultEventHistoryAction.updated,
          name: dto.item.name.valueOrNull ?? oldView.item.name,
          categoryId: dto.item.categoryId.valueOrNull ?? oldView.item.categoryId,
          iconRefId: dto.item.iconRefId.valueOrNull ?? oldView.item.iconRefId,
          snapshotHistoryId: snapshotRes?.getOrNull(),
        );
        if (eventRes.isError()) throw _InternalDbFailure(eventRes.exceptionOrNull()!);

        return const Success(unit);
      });
    } on _InternalDbFailure catch (e) {
      return Failure(e.error);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<DbResult<Unit>> softDelete(String itemId) {
    return vaultItemsStateService.softDelete(
      itemId: itemId,
      type: VaultItemType.note,
    );
  }

  Future<DbResult<Unit>> recover(String itemId) {
    return vaultItemsStateService.recover(
      itemId: itemId,
      type: VaultItemType.note,
    );
  }

  Future<DbResult<Unit>> archive(String itemId) {
    return vaultItemsStateService.archive(
      itemId: itemId,
      type: VaultItemType.note,
    );
  }

  Future<DbResult<Unit>> restoreArchived(String itemId) {
    return vaultItemsStateService.restoreArchived(
      itemId: itemId,
      type: VaultItemType.note,
    );
  }

  Future<DbResult<Unit>> setFavorite(String itemId, bool value) {
    return vaultItemsStateService.setFavorite(
      itemId: itemId,
      type: VaultItemType.note,
      value: value,
    );
  }

  Future<DbResult<Unit>> setPinned(String itemId, bool value) {
    return vaultItemsStateService.setPinned(
      itemId: itemId,
      type: VaultItemType.note,
      value: value,
    );
  }
}
