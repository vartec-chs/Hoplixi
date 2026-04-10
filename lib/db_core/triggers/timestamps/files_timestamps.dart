/// SQL триггеры временных меток для файлов.
///
/// @deprecated Файлы теперь хранятся в vault_items.
/// Используйте vaultItemsInsertTimestampTriggers и
/// vaultItemsModifiedAtTriggers из passwords_timestamps.dart.
library;

/// @deprecated
const List<String> filesInsertTimestampTriggers = [];

/// @deprecated
const List<String> filesModifiedAtTriggers = [];

/// @deprecated Удаляет устаревшие триггеры старой схемы.
const List<String> filesTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_files_timestamps;',
  'DROP TRIGGER IF EXISTS update_files_modified_at;',
];
