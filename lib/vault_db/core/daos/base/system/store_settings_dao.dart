import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/config/store_settings_keys.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../../tables/system/store/store_settings.dart';

part 'store_settings_dao.g.dart';

@DriftAccessor(tables: [StoreSettings])
class StoreSettingsDao extends DatabaseAccessor<VaultDB>
    with _$StoreSettingsDaoMixin {
  StoreSettingsDao(super.db);

  Future<String?> getRawValue(String key) async {
    final row = await (select(
      storeSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
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

  Future<String?> getSetting(String key) => getRawValue(key);

  Future<void> setSetting(String key, String value) =>
      setRawValue(key: key, value: value);

  Future<void> cleanupHistory({
    required int? maxAgeDays,
    required int? maxRecordsPerItem,
  }) async {
    // 1. Очистка по возрасту (age-based)
    if (maxAgeDays != null && maxAgeDays >= 0) {
      final cutOffDate = DateTime.now().subtract(Duration(days: maxAgeDays));

      // Удаляем старые снапшоты (связанные данные удалятся каскадно через FK)
      await (delete(db.vaultSnapshotsHistory)
            ..where((t) => t.historyCreatedAt.isSmallerThanValue(cutOffDate)))
          .go();

      // Удаляем старые события
      await (delete(db.vaultEventsHistory)
            ..where((t) => t.eventCreatedAt.isSmallerThanValue(cutOffDate)))
          .go();
    }

    // 2. Очистка по количеству (count-based)
    if (maxRecordsPerItem != null) {
      if (maxRecordsPerItem == 0) {
        // Полная очистка всей истории
        await delete(db.vaultSnapshotsHistory).go();
        await delete(db.vaultEventsHistory).go();
      } else if (maxRecordsPerItem > 0) {
        // Оставляем последние N записей для каждого элемента (item_id)
        await customStatement('''
          DELETE FROM vault_snapshots_history 
          WHERE id IN (
            SELECT id FROM (
              SELECT id, ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY history_created_at DESC) as rn
              FROM vault_snapshots_history
            ) WHERE rn > ?
          )
        ''', [maxRecordsPerItem]);
      }
    }
  }
}
