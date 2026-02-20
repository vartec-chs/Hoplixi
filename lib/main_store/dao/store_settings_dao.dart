import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/tables/store_settings.dart';

part 'store_settings_dao.g.dart';

@DriftAccessor(tables: [StoreSettings])
class StoreSettingsDao extends DatabaseAccessor<MainStore>
    with _$StoreSettingsDaoMixin {
  StoreSettingsDao(super.db);

  /// Get setting value by key
  Future<String?> getSetting(String key) async {
    final query = select(storeSettings)..where((t) => t.key.equals(key));
    final record = await query.getSingleOrNull();
    return record?.value;
  }

  /// Set setting value (insert or update)
  Future<void> setSetting(String key, String value) async {
    await into(
      storeSettings,
    ).insertOnConflictUpdate(StoreSetting(key: key, value: value));
  }

  /// Watch setting value by key
  Stream<String?> watchSetting(String key) {
    return (select(storeSettings)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((record) => record?.value);
  }

  /// Get all settings as a map
  Future<Map<String, String>> getAllSettings() async {
    final records = await select(storeSettings).get();
    return {for (var r in records) r.key: r.value};
  }

  /// Устаревшие записи истории
  Future<void> cleanupHistory({int? maxAgeDays, int? maxRecordsPerItem}) async {
    // 1. Сначала удаляем записи старше history_max_age_days
    if (maxAgeDays != null && maxAgeDays > 0) {
      await db.customStatement(
        '''
        DELETE FROM vault_item_history
        WHERE action_at < datetime('now', '-? days')
        ''',
        [maxAgeDays],
      );
    }

    // 2. Оставляем только `maxRecordsPerItem` записей для каждого itemId
    if (maxRecordsPerItem != null && maxRecordsPerItem > 0) {
      await db.customStatement(
        '''
        DELETE FROM vault_item_history
        WHERE id IN (
          SELECT id FROM (
            SELECT 
              id, 
              ROW_NUMBER() OVER (
                PARTITION BY item_id 
                ORDER BY action_at DESC
              ) as rn
            FROM vault_item_history
          ) 
          WHERE rn > ?
        )
        ''',
        [maxRecordsPerItem],
      );
    }
  }
}
