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

class StoreSettingsKeys {
  StoreSettingsKeys._();
  static const String historyLimit = 'history_limit';
  static const String historyMaxAgeDays = 'history_max_age_days';
  static const String historyEnabled = 'history_enabled';
  static const String historyCleanupIntervalDays =
      'history_cleanup_interval_days';
  static const String historyLastCleanupTimestamp =
      'history_last_cleanup_timestamp';
  static const String incrementUsageOnCopy = 'increment_usage_on_copy';
  static const String pinnedEntityTypes = 'pinned_entity_types';
}
