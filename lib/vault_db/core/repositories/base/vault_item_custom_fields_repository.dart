import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import '../../errors/db_error.dart';
import '../../errors/db_result.dart';

class VaultItemCustomFieldsRepository {
  final VaultDB db;

  VaultItemCustomFieldsRepository(this.db);

  AsyncDBResult<Unit> create(VaultItemCustomFieldsCompanion companion) {
    return tryCatchAsync(
      () async {
        await db.vaultItemCustomFieldsDao.insertCustomField(companion);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании настраиваемого поля',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> update(
    String id,
    VaultItemCustomFieldsCompanion companion,
  ) {
    return tryCatchAsync(
      () async {
        await db.vaultItemCustomFieldsDao.updateCustomFieldById(id, companion);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении настраиваемого поля',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Optional<VaultItemCustomFieldsData>> getById(String id) {
    return tryCatchAsync(
      () async {
        final data = await db.vaultItemCustomFieldsDao.getCustomFieldById(id);
        return Optional.fromNullable(data);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении настраиваемого поля',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<List<VaultItemCustomFieldsData>> getByItemId(String itemId) {
    return tryCatchAsync(
      () => db.vaultItemCustomFieldsDao.getCustomFieldsByItemId(itemId),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении настраиваемых полей элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<List<VaultItemCustomFieldsData>> getByItemIds(
    List<String> itemIds,
  ) {
    return tryCatchAsync(
      () => db.vaultItemCustomFieldsDao.getCustomFieldsByItemIds(itemIds),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении настраиваемых полей элементов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> delete(String id) {
    return tryCatchAsync(
      () async {
        await db.vaultItemCustomFieldsDao.deleteCustomFieldById(id);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении настраиваемого поля',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> deleteByItemId(String itemId) {
    return tryCatchAsync(
      () async {
        await db.vaultItemCustomFieldsDao.deleteCustomFieldsByItemId(itemId);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении настраиваемых полей элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> replaceFields({
    required String itemId,
    required List<VaultItemCustomFieldsCompanion> fields,
  }) {
    return tryCatchAsync(
      () async {
        await db.vaultItemCustomFieldsDao.replaceCustomFieldsForItem(
          itemId: itemId,
          fields: fields,
        );
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при замене настраиваемых полей',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
