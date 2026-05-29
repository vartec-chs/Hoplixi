import 'package:hoplixi/vault_db/core/models/dto/vault_item_base_dto.dart';
import 'package:hoplixi/vault_db/core/models/mappers/vault_item_mapper.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/tables.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import '../../errors/db_error.dart';
import '../../errors/db_result.dart';

class VaultItemRepository {
  final VaultDB db;

  VaultItemRepository(this.db);

  AsyncDbResult<Optional<VaultItemViewDto>> getById(String itemId) {
    return tryCatchAsync(
      () async {
        final row = await db.vaultItemsDao.getVaultItemById(itemId);
        return Optional.fromNullable(row?.toVaultItemViewDto());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении элемента хранилища',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<bool> exists(String itemId) {
    return tryCatchAsync(
      () => db.vaultItemsDao.existsVaultItem(itemId),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при проверке существования элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<bool> existsWithType(String itemId, VaultItemType type) {
    return tryCatchAsync(
      () => db.vaultItemsDao.existsVaultItemWithType(itemId, type),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message:
                  'Ошибка при проверке существования элемента заданного типа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> update(String itemId, VaultItemsCompanion companion) {
    return tryCatchAsync(
      () async {
        await db.vaultItemsDao.updateVaultItemById(itemId, companion);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении элемента хранилища',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> touch(String itemId) {
    return tryCatchAsync(
      () async {
        await db.vaultItemsDao.touchModifiedAt(itemId, DateTime.now());
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении времени изменения элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> incrementUsedCount(String itemId) {
    return tryCatchAsync(
      () async {
        await db.vaultItemsDao.incrementUsedCount(itemId, DateTime.now());
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при увеличении счетчика использования элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> archive(String itemId) {
    return tryCatchAsync(
      () async {
        await db.vaultItemsDao.archiveItem(itemId, DateTime.now());
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при архивации элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> restoreArchived(String itemId) {
    return tryCatchAsync(
      () async {
        await db.vaultItemsDao.restoreArchivedItem(itemId, DateTime.now());
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при восстановлении элемента из архива',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> softDelete(String itemId) {
    return tryCatchAsync(
      () async {
        await db.vaultItemsDao.softDeleteItem(itemId, DateTime.now());
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при мягком удалении элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> recover(String itemId) {
    return tryCatchAsync(
      () async {
        await db.vaultItemsDao.recoverDeletedItem(itemId, DateTime.now());
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при восстановлении удаленного элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> setFavorite(String itemId, bool isFavorite) {
    return tryCatchAsync(
      () async {
        await db.vaultItemsDao.setFavorite(itemId, isFavorite, DateTime.now());
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при изменении статуса избранного',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> setPinned(String itemId, bool isPinned) {
    return tryCatchAsync(
      () async {
        await db.vaultItemsDao.setPinned(itemId, isPinned, DateTime.now());
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при изменении статуса закрепления',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
