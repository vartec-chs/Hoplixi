/// SQL триггеры временных меток для банковских карт.
///
/// @deprecated Банковские карты теперь хранятся в vault_items.
/// Используйте vaultItemsInsertTimestampTriggers и
/// vaultItemsModifiedAtTriggers из passwords_timestamps.dart.
library;

/// @deprecated
const List<String> bankCardsInsertTimestampTriggers = [];

/// @deprecated
const List<String> bankCardsModifiedAtTriggers = [];

/// @deprecated Удаляет устаревшие триггеры старой схемы.
const List<String> bankCardsTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_bank_cards_timestamps;',
  'DROP TRIGGER IF EXISTS update_bank_cards_modified_at;',
];
