import 'dart:typed_data';

import 'package:hoplixi/vault_db/core/errors/db_error.dart';
import 'package:hoplixi/vault_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/repositories/base/otp_repository.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_events_history.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';
import 'package:hoplixi/vault_db/core/services/entities/base_vault_entity_service.dart';
import 'package:hoplixi/vault_db/core/validators/otp_validator.dart';
import 'package:result_dart/result_dart.dart';

class OtpService extends BaseVaultEntityService<OtpRepository> {
  OtpService({required super.deps, required super.repository});

  Future<DBResult<String>> create(CreateOtpDto dto) async {
    final validationError = validateCreateOtp(dto);
    if (validationError != null) return Failure(validationError);

    try {
      return await db.transaction(() async {
        // 1. Создаем запись в репозитории
        final itemId = (await repository.create(dto)).getOrThrow();

        // 3. Получаем созданное состояние для snapshot
        final createdViewResult = await repository.getViewById(itemId);
        final createdView = createdViewResult.getOrThrow().fold(
          (view) => view,
          () => throw DBCoreError.notFound(
            entity: 'otp',
            id: itemId,
            message: 'Failed to retrieve created Otp: $itemId',
          ),
        );

        // 4. Пишем snapshot created (After create)
        final snapshotRes = (await historyService.snapshotAfterCreate(
          createdView: createdView,
          action: VaultEventHistoryAction.created,
        )).getOrThrow();

        // 5. Пишем event created
        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.otp,
          action: VaultEventHistoryAction.created,
          name: createdView.item.name,
          snapshotHistoryId: snapshotRes.getOrNull(),
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

  Future<DBResult<List<String>>> createMany(List<CreateOtpDto> dtos) async {
    for (final dto in dtos) {
      final validationError = validateCreateOtp(dto);
      if (validationError != null) return Failure(validationError);
    }

    try {
      return await db.transaction(() async {
        final List<String> itemIds = [];

        for (final dto in dtos) {
          // 1. Создаем запись в репозитории
          final itemId = (await repository.create(dto)).getOrThrow();

          // 2. Получаем созданное состояние для snapshot
          final createdViewResult = await repository.getViewById(itemId);
          final createdView = createdViewResult.getOrThrow().fold(
            (view) => view,
            () => throw DBCoreError.notFound(
              entity: 'otp',
              id: itemId,
              message: 'Failed to retrieve created Otp: $itemId',
            ),
          );

          // 3. Пишем snapshot created (After create)
          final snapshotRes = (await historyService.snapshotAfterCreate(
            createdView: createdView,
            action: VaultEventHistoryAction.created,
          )).getOrThrow();

          // 4. Пишем event created
          final eventRes = await historyService.writeEvent(
            itemId: itemId,
            type: VaultItemType.otp,
            action: VaultEventHistoryAction.created,
            name: createdView.item.name,
            snapshotHistoryId: snapshotRes.getOrNull(),
          );
          if (eventRes.isError()) throw eventRes.exceptionOrNull()!;

          itemIds.add(itemId);
        }

        return Success(itemIds);
      });
    } on DBCoreError catch (e) {
      return Failure(e);
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  Future<DBResult<Optional<Uint8List>>> getSecretByItemId(String itemId) {
    return repository.getSecretByItemId(itemId);
  }

  Future<DBResult<Unit>> update(PatchOtpDto dto) async {
    final validationError = validatePatchOtp(dto);
    if (validationError != null) return Failure(validationError);

    try {
      return await db.transaction(() async {
        final itemId = dto.item.itemId;

        // 1. Получаем старое состояние для snapshot
        final oldView = (await repository.getViewById(
          itemId,
        )).getOrThrow().getOrNull();
        if (oldView == null) {
          throw DBCoreError.notFound(
            entity: 'otp',
            id: itemId,
            message: 'Otp not found for update: $itemId',
          );
        }

        // 2. Пишем snapshot before update
        final snapshotRes = (await historyService.snapshotBeforeUpdate(
          oldView: oldView,
          action: VaultEventHistoryAction.updated,
        )).getOrThrow();

        // 3. Обновляем данные в репозитории
        (await repository.update(dto)).getOrThrow();

        // 5. Пишем event updated
        final eventRes = await historyService.writeEvent(
          itemId: itemId,
          type: VaultItemType.otp,
          action: VaultEventHistoryAction.updated,
          name: dto.item.name.valueOrNull ?? oldView.item.name,
          snapshotHistoryId: snapshotRes.getOrNull(),
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

  Future<DBResult<Unit>> softDelete(String itemId) {
    return vaultItemsStateService.softDelete(
      itemId: itemId,
      type: VaultItemType.otp,
    );
  }

  Future<DBResult<Unit>> recover(String itemId) {
    return vaultItemsStateService.recover(
      itemId: itemId,
      type: VaultItemType.otp,
    );
  }

  Future<DBResult<Unit>> archive(String itemId) {
    return vaultItemsStateService.archive(
      itemId: itemId,
      type: VaultItemType.otp,
    );
  }

  Future<DBResult<Unit>> restoreArchived(String itemId) {
    return vaultItemsStateService.restoreArchived(
      itemId: itemId,
      type: VaultItemType.otp,
    );
  }

  Future<DBResult<Unit>> setFavorite(String itemId, bool value) {
    return vaultItemsStateService.setFavorite(
      itemId: itemId,
      type: VaultItemType.otp,
      value: value,
    );
  }

  Future<DBResult<Unit>> setPinned(String itemId, bool value) {
    return vaultItemsStateService.setPinned(
      itemId: itemId,
      type: VaultItemType.otp,
      value: value,
    );
  }
}
