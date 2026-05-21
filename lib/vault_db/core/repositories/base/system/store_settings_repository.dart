import 'package:hoplixi/vault_db/core/config/store_settings_keys.dart';
import 'package:hoplixi/vault_db/core/tables/system/store/store_settings.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

class StoreSettingsRepository {
  final VaultDB db;

  StoreSettingsRepository(this.db);

  Future<String?> getRawValue(String key) {
    return db.storeSettingsDao.getRawValue(key);
  }

  Future<void> setRawValue({
    required String key,
    required String value,
    StoreSettingValueType valueType = StoreSettingValueType.string,
  }) {
    return db.storeSettingsDao.setRawValue(
      key: key,
      value: value,
      valueType: valueType,
    );
  }

  Future<void> deleteSetting(String key) {
    return db.storeSettingsDao.deleteSetting(key);
  }

  Future<List<StoreSettingData>> getAllSettings() {
    return db.storeSettingsDao.getAllSettings();
  }

  Future<int?> getInt(StoreSettingsKey key) {
    return db.storeSettingsDao.getInt(key);
  }

  Future<bool?> getBool(StoreSettingsKey key) {
    return db.storeSettingsDao.getBool(key);
  }

  Future<String?> getString(StoreSettingsKey key) {
    return db.storeSettingsDao.getString(key);
  }

  Future<void> setInt(StoreSettingsKey key, int value) {
    return db.storeSettingsDao.setInt(key, value);
  }

  Future<void> setBool(StoreSettingsKey key, bool value) {
    return db.storeSettingsDao.setBool(key, value);
  }

  Future<void> setString(StoreSettingsKey key, String value) {
    return db.storeSettingsDao.setString(key, value);
  }
}
