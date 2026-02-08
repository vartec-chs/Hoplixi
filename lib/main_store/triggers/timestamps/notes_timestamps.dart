/// SQL триггеры для автоматического управления временными метками таблицы notes.
///
/// Эти триггеры автоматически устанавливают `created_at` и `modified_at`
/// при вставке и обновлении записей.
library;

/// Триггеры для установки временных меток при вставке.
const List<String> notesInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_notes_timestamps
    AFTER INSERT ON notes
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE notes 
      SET 
        created_at = COALESCE(NEW.created_at, strftime('%s','now')  ),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now')  )
      WHERE id = NEW.id;
    END;
  ''',
];

/// Триггеры для обновления modified_at при изменении записи.
const List<String> notesModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_notes_modified_at
    AFTER UPDATE ON notes
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE notes 
      SET modified_at = strftime('%s', 'now')  
      WHERE id = NEW.id;
    END;
  ''',
];

/// Операторы для удаления триггеров временных меток notes.
const List<String> notesTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_notes_timestamps;',
  'DROP TRIGGER IF EXISTS update_notes_modified_at;',
];
