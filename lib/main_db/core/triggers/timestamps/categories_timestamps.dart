/// SQL триггеры для автоматического управления временными метками таблицы categories.
///
/// Эти триггеры автоматически устанавливают `created_at` и `modified_at`
/// при вставке и обновлении записей.
library;

/// Триггеры для установки временных меток при вставке.
const List<String> categoriesInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_categories_timestamps
    AFTER INSERT ON categories
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE categories 
      SET 
        created_at = COALESCE(NEW.created_at, strftime('%s','now')  ),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now')  )
      WHERE id = NEW.id;
    END;
  ''',
];

/// Триггеры для обновления modified_at при изменении записи.
const List<String> categoriesModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_categories_modified_at
    AFTER UPDATE ON categories
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE categories 
      SET modified_at = strftime('%s', 'now')  
      WHERE id = NEW.id;
    END;
  ''',
];

/// Операторы для удаления триггеров временных меток categories.
const List<String> categoriesTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_categories_timestamps;',
  'DROP TRIGGER IF EXISTS update_categories_modified_at;',
];
