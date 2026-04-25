/// SQL триггеры для автоматического управления временными метками таблицы tags.
///
/// Эти триггеры автоматически устанавливают `created_at` и `modified_at`
/// при вставке и обновлении записей.
library;

/// Триггеры для установки временных меток при вставке.
const List<String> tagsInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_tags_timestamps
    AFTER INSERT ON tags
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE tags 
      SET 
        created_at = COALESCE(NEW.created_at, strftime('%s','now')  ),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now')  )
      WHERE id = NEW.id;
    END;
  ''',
];

/// Триггеры для обновления modified_at при изменении записи.
const List<String> tagsModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_tags_modified_at
    AFTER UPDATE ON tags
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE tags 
      SET modified_at = strftime('%s', 'now')  
      WHERE id = NEW.id;
    END;
  ''',
];

/// Операторы для удаления триггеров временных меток tags.
const List<String> tagsTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_tags_timestamps;',
  'DROP TRIGGER IF EXISTS update_tags_modified_at;',
];
