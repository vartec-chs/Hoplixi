import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/config/store_settings_keys.dart';
import '../../../main_store.dart';
import '../../../tables/system/store/store_settings.dart';

part 'store_settings_dao.g.dart';



@DriftAccessor(tables: [StoreSettings])
class StoreSettingsDao extends DatabaseAccessor<MainStore> with _$StoreSettingsDaoMixin {
  StoreSettingsDao(super.db);

  Future<String?> getRawValue(String key) async {
    final row = await (select(storeSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setRawValue({
    required String key,
    required String value,
    StoreSettingValueType valueType = StoreSettingValueType.string,
  }) {
    return into(storeSettings).insertOnConflictUpdate(
      StoreSettingsCompanion.insert(
        key: key,
        value: value,
        valueType: Value(valueType),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteSetting(String key) {
    return (delete(storeSettings)..where((t) => t.key.equals(key))).go();
  }

  Future<List<StoreSettingData>> getAllSettings() {
    return select(storeSettings).get();
  }

  Future<int?> getInt(StoreSettingsKey key) async {
    final val = await getRawValue(key.storageKey);
    return val != null ? int.tryParse(val) : null;
  }

  Future<bool?> getBool(StoreSettingsKey key) async {
    final val = await getRawValue(key.storageKey);
    if (val == null) return null;
    return val.toLowerCase() == 'true';
  }

  Future<String?> getString(StoreSettingsKey key) {
    return getRawValue(key.storageKey);
  }

  Future<void> setInt(StoreSettingsKey key, int value) {
    return setRawValue(
      key: key.storageKey,
      value: value.toString(),
      valueType: StoreSettingValueType.int,
    );
  }

  Future<void> setBool(StoreSettingsKey key, bool value) {
    return setRawValue(
      key: key.storageKey,
      value: value.toString(),
      valueType: StoreSettingValueType.bool,
    );
  }

  Future<void> setString(StoreSettingsKey key, String value) {
    return setRawValue(
      key: key.storageKey,
      value: value,
      valueType: StoreSettingValueType.string,
    );
  }
}
