/// SQL триггеры для автоматического управления временными метками таблицы passwords.
///
/// Эти триггеры автоматически устанавливают `created_at` и `modified_at`
/// при вставке и обновлении записей.
library;

/// Триггеры для установки временных меток при вставке.
const List<String> passwordsInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_passwords_timestamps
    AFTER INSERT ON passwords
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE passwords 
      SET 
        created_at = COALESCE(NEW.created_at, strftime('%s','now')  ),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now')  )
      WHERE id = NEW.id;
    END;
  ''',
];

/// Триггеры для обновления modified_at при изменении записи.
const List<String> passwordsModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_passwords_modified_at
    AFTER UPDATE ON passwords
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE passwords 
      SET modified_at = strftime('%s', 'now')  
      WHERE id = NEW.id;
    END;
  ''',
];

/// Операторы для удаления триггеров временных меток passwords.
const List<String> passwordsTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_passwords_timestamps;',
  'DROP TRIGGER IF EXISTS update_passwords_modified_at;',
];
