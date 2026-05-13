enum StoreSettingsKey {
  historyLimit('history_limit'),
  historyMaxAgeDays('history_max_age_days'),
  historyEnabled('history_enabled'),
  historyCleanupIntervalDays('history_cleanup_interval_days'),
  historyLastCleanupTimestamp('history_last_cleanup_timestamp'),
  incrementUsageOnCopy('increment_usage_on_copy'),
  pinnedEntityTypes('pinned_entity_types');

  const StoreSettingsKey(this.key);

  final String key;
}
