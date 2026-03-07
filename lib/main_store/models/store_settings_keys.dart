class StoreSettingsKeys {
  static const String historyLimit = 'history_limit';
  static const String historyMaxAgeDays = 'history_max_age_days';
  static const String historyEnabled = 'history_enabled';
  static const String historyCleanupIntervalDays =
      'history_cleanup_interval_days';
  static const String historyLastCleanupTimestamp =
      'history_last_cleanup_timestamp';

  /// Закреплённые типы сущностей в выпадающем списке (JSON-массив id)
  static const String pinnedEntityTypes = 'pinned_entity_types';

  // Private constructor to prevent instantiation
  StoreSettingsKeys._();
}
