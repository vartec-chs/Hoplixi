import 'package:hoplixi/vault_db/core/config/store_settings_keys.dart';
import 'package:hoplixi/vault_db/core/tables/system/store/store_settings.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';

class StoreSettingsRepository {
  final VaultDB db;

  StoreSettingsRepository(this.db);

  AsyncDbResult<Optional<String>> getRawValue(String key) {
    return ResultUtils.tryCatchAsync(
      () async {
        final data = await db.storeSettingsDao.getRawValue(key);
        return Optional.fromNullable(data);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении сырого значения настройки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> setRawValue({
    required String key,
    required String value,
    StoreSettingValueType valueType = StoreSettingValueType.string,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.storeSettingsDao.setRawValue(
          key: key,
          value: value,
          valueType: valueType,
        );
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при установке сырого значения настройки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deleteSetting(String key) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.storeSettingsDao.deleteSetting(key);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении настройки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<StoreSettingData>> getAllSettings() {
    return ResultUtils.tryCatchAsync(
      () => db.storeSettingsDao.getAllSettings(),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении всех настроек',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<int>> getInt(StoreSettingsKey key) {
    return ResultUtils.tryCatchAsync(
      () async {
        final data = await db.storeSettingsDao.getInt(key);
        return Optional.fromNullable(data);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении целочисленной настройки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<bool>> getBool(StoreSettingsKey key) {
    return ResultUtils.tryCatchAsync(
      () async {
        final data = await db.storeSettingsDao.getBool(key);
        return Optional.fromNullable(data);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении логической настройки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<String>> getString(StoreSettingsKey key) {
    return ResultUtils.tryCatchAsync(
      () async {
        final data = await db.storeSettingsDao.getString(key);
        return Optional.fromNullable(data);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении строковой настройки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> setInt(StoreSettingsKey key, int value) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.storeSettingsDao.setInt(key, value);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при установке целочисленной настройки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> setBool(StoreSettingsKey key, bool value) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.storeSettingsDao.setBool(key, value);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при установке логической настройки',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> setString(StoreSettingsKey key, String value) {
    return ResultUtils.tryCatchAsync(
      () async {
        await db.storeSettingsDao.setString(key, value);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при установке строковой настройки',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}

