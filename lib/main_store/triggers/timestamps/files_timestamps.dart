/// SQL триггеры для автоматического управления временными метками таблицы files.
///
/// Эти триггеры автоматически устанавливают `created_at` и `modified_at`
/// при вставке и обновлении записей.
library;

/// Триггеры для установки временных меток при вставке.
const List<String> filesInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_files_timestamps
    AFTER INSERT ON files
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE files 
      SET 
        created_at = COALESCE(NEW.created_at, strftime('%s','now')  ),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now')  )
      WHERE id = NEW.id;
    END;
  ''',
];

/// Триггеры для обновления modified_at при изменении записи.
const List<String> filesModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_files_modified_at
    AFTER UPDATE ON files
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE files 
      SET modified_at = strftime('%s', 'now')  
      WHERE id = NEW.id;
    END;
  ''',
];

/// Операторы для удаления триггеров временных меток files.
const List<String> filesTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_files_timestamps;',
  'DROP TRIGGER IF EXISTS update_files_modified_at;',
];
