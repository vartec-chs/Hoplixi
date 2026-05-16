import 'package:hoplixi/main_db/config/store_settings_keys.dart';
import 'package:hoplixi/main_db/core/dao/system/store_settings_dao.dart';

class StoreHistoryPolicyService {
  StoreHistoryPolicyService(this.settingsDao);

  final StoreSettingsDao settingsDao;

  Future<bool> isHistoryEnabled() async {
    return await settingsDao.getBool(StoreSettingsKey.historyEnabled) ?? true;
  }

  Future<int?> historyLimit() {
    return settingsDao.getInt(StoreSettingsKey.historyLimit);
  }

  Future<int?> historyMaxAgeDays() {
    return settingsDao.getInt(StoreSettingsKey.historyMaxAgeDays);
  }

  Future<bool> incrementUsageOnCopy() async {
    return await settingsDao.getBool(StoreSettingsKey.incrementUsageOnCopy) ??
        true;
  }
}
