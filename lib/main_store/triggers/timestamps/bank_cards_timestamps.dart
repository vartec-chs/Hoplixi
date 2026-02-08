/// SQL триггеры для автоматического управления временными метками таблицы bank_cards.
///
/// Эти триггеры автоматически устанавливают `created_at` и `modified_at`
/// при вставке и обновлении записей.
library;

/// Триггеры для установки временных меток при вставке.
const List<String> bankCardsInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_bank_cards_timestamps
    AFTER INSERT ON bank_cards
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE bank_cards 
      SET 
        created_at = COALESCE(NEW.created_at, strftime('%s','now')  ),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now')  )
      WHERE id = NEW.id;
    END;
  ''',
];

/// Триггеры для обновления modified_at при изменении записи.
const List<String> bankCardsModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_bank_cards_modified_at
    AFTER UPDATE ON bank_cards
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE bank_cards 
      SET modified_at = strftime('%s', 'now')  
      WHERE id = NEW.id;
    END;
  ''',
];

/// Операторы для удаления триггеров временных меток bank_cards.
const List<String> bankCardsTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_bank_cards_timestamps;',
  'DROP TRIGGER IF EXISTS update_bank_cards_modified_at;',
];
