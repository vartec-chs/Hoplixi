/// SQL триггеры временных меток для документов.
///
/// @deprecated Документы теперь хранятся в vault_items.
/// Используйте vaultItemsInsertTimestampTriggers и
/// vaultItemsModifiedAtTriggers из passwords_timestamps.dart.
library;

/// @deprecated
const List<String> documentsInsertTimestampTriggers = [];

/// @deprecated
const List<String> documentsModifiedAtTriggers = [];

/// @deprecated Удаляет устаревшие триггеры старой схемы.
const List<String> documentsTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_documents_timestamps;',
  'DROP TRIGGER IF EXISTS update_documents_modified_at;',
];
