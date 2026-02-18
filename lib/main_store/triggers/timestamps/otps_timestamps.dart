/// SQL триггеры временных меток для OTP-кодов.
///
/// @deprecated OTP-коды теперь хранятся в vault_items.
/// Используйте vaultItemsInsertTimestampTriggers и
/// vaultItemsModifiedAtTriggers из passwords_timestamps.dart.
library;

/// @deprecated
const List<String> otpsInsertTimestampTriggers = [];

/// @deprecated
const List<String> otpsModifiedAtTriggers = [];

/// @deprecated Удаляет устаревшие триггеры старой схемы.
const List<String> otpsTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_otps_timestamps;',
  'DROP TRIGGER IF EXISTS update_otps_modified_at;',
];
