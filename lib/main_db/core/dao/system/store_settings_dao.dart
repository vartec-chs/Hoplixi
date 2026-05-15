import 'package:drift/drift.dart';
import '../../main_store.dart';
import '../../tables/system/store/store_settings.dart';

part 'store_settings_dao.g.dart';

enum StoreSettingsKey {
  historyLimit('history_limit'),
  historyMaxAgeDays('history_max_age_days'),
  historyEnabled('history_enabled'),
  historyCleanupIntervalDays('history_cleanup_interval_days'),
  historyLastCleanupTimestamp('history_last_cleanup_timestamp'),
  incrementUsageOnCopy('increment_usage_on_copy'),
  pinnedEntityTypes('pinned_entity_types');

  const StoreSettingsKey(this.storageKey);

  final String storageKey;

  static StoreSettingsKey? fromStorageKey(String value) {
    for (final key in values) {
      if (key.storageKey == value) return key;
    }
    return null;
  }
}

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
