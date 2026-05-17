import 'package:hoplixi/main_db/core/errors/db_error.dart';
import 'package:hoplixi/main_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/main_db/core/errors/db_result.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/repositories/base/loyalty_card_repository.dart';
import 'package:hoplixi/main_db/core/services/history/facades/vault_history_service.dart';
import 'package:hoplixi/main_db/core/services/vault_items_state_service.dart';
import 'package:hoplixi/main_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/main_db/core/tables/vault_items/vault_items.dart';
import 'package:hoplixi/main_db/core/validators/loyalty_card_validator.dart';
import 'package:result_dart/result_dart.dart';

import '../../main_store.dart';

class LoyaltyCardService {
  LoyaltyCardService({
    required this.db,
    required this.repository,
    required this.relationsService,
    required this.historyService,
    required this.vaultItemsStateService,
  });

  final MainStore db;
  final LoyaltyCardRepository repository;
  final VaultItemRelationsService relationsService;
  final VaultHistoryService historyService;
  final VaultItemsStateService vaultItemsStateService;

  Future<DbResult<String>> create(CreateLoyaltyCardDto dto) async {
    final validationError = validateCreateLoyaltyCard(dto);
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
            entity: 'loyaltyCard',
            id: itemId,
            message: 'Failed to retrieve created LoyaltyCard: $itemId',
          );
        }

        final snapshotRes = await historyService.snapshotAfterCreate(
          createdView: createdView,
          action: VaultEventHistoryAction.created,
        );
        if (snapshotRes != null && snapshotRes.isError()) {
          throw snapshotRes.exceptionOrNull()!;
        }

        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.loyaltyCard,
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

  Future<DbResult<Unit>> update(PatchLoyaltyCardDto dto) async {
    final validationError = validatePatchLoyaltyCard(dto);
    if (validationError != null) return Failure(validationError);

    try {
      return await db.transaction(() async {
        final itemId = dto.item.itemId;

        final oldView = await repository.getViewById(itemId);
        if (oldView == null) {
          throw DBCoreError.notFound(
            entity: 'loyaltyCard',
            id: itemId,
            message: 'LoyaltyCard not found for update: $itemId',
          );
        }

        final snapshotRes = await historyService.snapshotBeforeUpdate(
          oldView: oldView,
          action: VaultEventHistoryAction.updated,
        );
        if (snapshotRes != null && snapshotRes.isError()) {
          throw snapshotRes.exceptionOrNull()!;
        }

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
          type: VaultItemType.loyaltyCard,
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
      type: VaultItemType.loyaltyCard,
    );
  }

  Future<DbResult<Unit>> recover(String itemId) {
    return vaultItemsStateService.recover(
      itemId: itemId,
      type: VaultItemType.loyaltyCard,
    );
  }

  Future<DbResult<Unit>> archive(String itemId) {
    return vaultItemsStateService.archive(
      itemId: itemId,
      type: VaultItemType.loyaltyCard,
    );
  }

  Future<DbResult<Unit>> restoreArchived(String itemId) {
    return vaultItemsStateService.restoreArchived(
      itemId: itemId,
      type: VaultItemType.loyaltyCard,
    );
  }

  Future<DbResult<Unit>> setFavorite(String itemId, bool value) {
    return vaultItemsStateService.setFavorite(
      itemId: itemId,
      type: VaultItemType.loyaltyCard,
      value: value,
    );
  }

  Future<DbResult<Unit>> setPinned(String itemId, bool value) {
    return vaultItemsStateService.setPinned(
      itemId: itemId,
      type: VaultItemType.loyaltyCard,
      value: value,
    );
  }
}
