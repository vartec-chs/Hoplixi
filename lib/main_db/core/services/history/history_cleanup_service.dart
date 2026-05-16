import 'package:hoplixi/main_db/core/dao/system/store_settings_dao.dart';

class HistoryCleanupService {
  HistoryCleanupService(this.settingsDao);

  final StoreSettingsDao settingsDao;

  Future<void> maybeCleanup() async {
    // TODO: implement cleanup by historyLimit/historyMaxAgeDays
    // 1. Проверить StoreSettingsKey.historyLastCleanupTimestamp
    // 2. Если прошло достаточно времени (historyCleanupIntervalDays)
    // 3. Выполнить очистку в фоновом режиме
  }
}
