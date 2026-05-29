import 'package:hoplixi/vault_db/core/config/store_settings_keys.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/store/store_settings.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';

class StoreSettingsRepository {
  final VaultDB db;

  StoreSettingsRepository(this.db);

  AsyncDbResult<Optional<String>> getRawValue(String key) {
    return tryCatchAsync(
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
    return tryCatchAsync(
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
    return tryCatchAsync(
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
    return tryCatchAsync(
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

  AsyncDbResult<Optional<T>> get<T extends Object>(StoreSettingsKey<T> key) {
    return tryCatchAsync(
      () async {
        final raw = await db.storeSettingsDao.getRawValue(key.storageKey);

        if (raw == null) {
          return Optional.fromNullable(null);
        }

        final value = key.codec.decode(raw);
        return Optional.fromNullable(value);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении настройки ${key.storageKey}',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<T> getOrDefault<T extends Object>(StoreSettingsKey<T> key) {
    return tryCatchAsync(
      () async {
        final raw = await db.storeSettingsDao.getRawValue(key.storageKey);

        if (raw == null) {
          return key.defaultValue;
        }

        return key.codec.decode(raw);
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message:
                  'Ошибка при получении настройки ${key.storageKey} со значением по умолчанию',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> set<T>(StoreSettingsKey<T> key, T value) {
    return tryCatchAsync(
      () async {
        await db.storeSettingsDao.setRawValue(
          key: key.storageKey,
          value: key.codec.encode(value),
          valueType: key.valueType,
        );

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при установке настройки ${key.storageKey}',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> initializeDefaults() {
    return tryCatchAsync(
      () async {
        for (final key in StoreSettingsKey.values) {
          final raw = await db.storeSettingsDao.getRawValue(key.storageKey);

          if (raw != null) continue;

          await db.storeSettingsDao.setRawValue(
            key: key.storageKey,
            value: key.codec.encode(key.defaultValue),
            valueType: key.valueType,
          );
        }

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при инициализации настроек хранилища',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> repairSettings() {
    return tryCatchAsync(
      () async {
        for (final key in StoreSettingsKey.values) {
          final raw = await db.storeSettingsDao.getRawValue(key.storageKey);

          if (raw == null) {
            await db.storeSettingsDao.setRawValue(
              key: key.storageKey,
              value: key.codec.encode(key.defaultValue),
              valueType: key.valueType,
            );
            continue;
          }

          try {
            final decoded = key.codec.decode(raw);

            await db.storeSettingsDao.setRawValue(
              key: key.storageKey,
              value: key.codec.encode(decoded),
              valueType: key.valueType,
            );
          } catch (_) {
            await db.storeSettingsDao.setRawValue(
              key: key.storageKey,
              value: key.codec.encode(key.defaultValue),
              valueType: key.valueType,
            );
          }
        }

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при починке настроек хранилища',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
