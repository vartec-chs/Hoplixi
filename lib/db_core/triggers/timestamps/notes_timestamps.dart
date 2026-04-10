/// SQL триггеры временных меток для заметок.
///
/// @deprecated Заметки теперь хранятся в vault_items.
/// Используйте vaultItemsInsertTimestampTriggers и
/// vaultItemsModifiedAtTriggers из passwords_timestamps.dart.
library;

/// @deprecated
const List<String> notesInsertTimestampTriggers = [];

/// @deprecated
const List<String> notesModifiedAtTriggers = [];

/// @deprecated Удаляет устаревшие триггеры старой схемы.
const List<String> notesTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_notes_timestamps;',
  'DROP TRIGGER IF EXISTS update_notes_modified_at;',
];
