/// SQL триггеры для автоматического управления временными метками таблицы vault_items.
///
/// Заменяет отдельные триггеры для passwords, notes, bank_cards, otps, files,
/// documents — теперь все сущности хранятся в одной таблице vault_items.
library;

/// Триггеры для установки временных меток при вставке.
const List<String> vaultItemsInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_vault_items_timestamps
    AFTER INSERT ON vault_items
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE vault_items
      SET
        created_at = COALESCE(NEW.created_at, strftime('%s','now')),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now'))
      WHERE id = NEW.id;
    END;
  ''',
];

/// Триггеры для обновления modified_at при изменении записи.
const List<String> vaultItemsModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_vault_items_modified_at
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE vault_items
      SET modified_at = strftime('%s', 'now')
      WHERE id = NEW.id;
    END;
  ''',
];

/// Операторы для удаления триггеров временных меток vault_items.
const List<String> vaultItemsTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_vault_items_timestamps;',
  'DROP TRIGGER IF EXISTS update_vault_items_modified_at;',
];

// ---------------------------------------------------------------------------
// Алиасы для обратной совместимости с index.dart
// (старые имена экспортируются как пустые списки — триггеры удалены)
// ---------------------------------------------------------------------------

/// @deprecated Используйте vaultItemsInsertTimestampTriggers
const List<String> passwordsInsertTimestampTriggers = [];

/// @deprecated Используйте vaultItemsModifiedAtTriggers
const List<String> passwordsModifiedAtTriggers = [];

/// @deprecated
const List<String> passwordsTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_passwords_timestamps;',
  'DROP TRIGGER IF EXISTS update_passwords_modified_at;',
];
