import 'package:hoplixi/main_db/core/errors/db_error.dart';
import 'package:hoplixi/main_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/main_db/core/errors/db_result.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/repositories/base/certificate_repository.dart';
import 'package:hoplixi/main_db/core/services/history/vault_history_service.dart';
import 'package:hoplixi/main_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:hoplixi/main_db/core/validators/certificate_validator.dart';
import 'package:result_dart/result_dart.dart';

import '../../main_store.dart';

class _InternalDbFailure implements Exception {
  const _InternalDbFailure(this.error);
  final DbError error;
}

class CertificateService {
  CertificateService({
    required this.db,
    required this.repository,
    required this.relationsService,
    required this.historyService,
  });

  final MainStore db;
  final CertificateRepository repository;
  final VaultItemRelationsService relationsService;
  final VaultHistoryService historyService;

  Future<DbResult<String>> create(CreateCertificateDto dto) async {
    final validationError = validateCreateCertificate(dto);
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
            entity: 'certificate',
            id: itemId,
            message: 'Failed to retrieve created Certificate: $itemId',
          ));
        }

        final snapshotRes = await historyService.snapshotAfterCreate(
          type: VaultItemType.certificate,
          createdView: createdView,
          action: VaultEventHistoryAction.created,
        );
        if (snapshotRes != null && snapshotRes.isError()) throw _InternalDbFailure(snapshotRes.exceptionOrNull()!);

        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.certificate,
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

  Future<DbResult<Unit>> update(PatchCertificateDto dto) async {
    final validationError = validatePatchCertificate(dto);
    if (validationError != null) return Failure(validationError);

    try {
      return await db.transaction(() async {
        final itemId = dto.item.itemId;

        final oldView = await repository.getViewById(itemId);
        if (oldView == null) {
          throw _InternalDbFailure(DbError.notFound(
            entity: 'certificate',
            id: itemId,
            message: 'Certificate not found for update: $itemId',
          ));
        }

        final snapshotRes = await historyService.snapshotBeforeUpdate(
          type: VaultItemType.certificate,
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
          type: VaultItemType.certificate,
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

  Future<DbResult<Unit>> softDelete(String itemId) async {
    try {
      return await db.transaction(() async {
        final oldView = await repository.getViewById(itemId);
        if (oldView == null) return const Success(unit);

        final snapshotRes = await historyService.snapshotBeforeUpdate(
          type: VaultItemType.certificate,
          oldView: oldView,
          action: VaultEventHistoryAction.deleted,
        );
        if (snapshotRes != null && snapshotRes.isError()) throw _InternalDbFailure(snapshotRes.exceptionOrNull()!);

        await db.vaultItemsDao.softDeleteItem(itemId, DateTime.now());

        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.certificate,
          action: VaultEventHistoryAction.deleted,
          name: oldView.item.name,
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

  Future<DbResult<Unit>> recover(String itemId) async {
    try {
      return await db.transaction(() async {
        final oldView = await repository.getViewById(itemId);
        if (oldView == null) return const Success(unit);

        final snapshotRes = await historyService.snapshotBeforeUpdate(
          type: VaultItemType.certificate,
          oldView: oldView,
          action: VaultEventHistoryAction.recovered,
        );
        if (snapshotRes != null && snapshotRes.isError()) throw _InternalDbFailure(snapshotRes.exceptionOrNull()!);

        await db.vaultItemsDao.recoverDeletedItem(itemId, DateTime.now());

        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.certificate,
          action: VaultEventHistoryAction.recovered,
          name: oldView.item.name,
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

  Future<DbResult<Unit>> archive(String itemId) async {
    try {
      return await db.transaction(() async {
        final oldView = await repository.getViewById(itemId);
        if (oldView == null) return const Success(unit);

        final snapshotRes = await historyService.snapshotBeforeUpdate(
          type: VaultItemType.certificate,
          oldView: oldView,
          action: VaultEventHistoryAction.archived,
        );
        if (snapshotRes != null && snapshotRes.isError()) throw _InternalDbFailure(snapshotRes.exceptionOrNull()!);

        await db.vaultItemsDao.archiveItem(itemId, DateTime.now());

        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.certificate,
          action: VaultEventHistoryAction.archived,
          name: oldView.item.name,
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

  Future<DbResult<Unit>> restoreArchived(String itemId) async {
    try {
      return await db.transaction(() async {
        final oldView = await repository.getViewById(itemId);
        if (oldView == null) return const Success(unit);

        final snapshotRes = await historyService.snapshotBeforeUpdate(
          type: VaultItemType.certificate,
          oldView: oldView,
          action: VaultEventHistoryAction.restored,
        );
        if (snapshotRes != null && snapshotRes.isError()) throw _InternalDbFailure(snapshotRes.exceptionOrNull()!);

        await db.vaultItemsDao.restoreArchivedItem(itemId, DateTime.now());

        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.certificate,
          action: VaultEventHistoryAction.restored,
          name: oldView.item.name,
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
}

