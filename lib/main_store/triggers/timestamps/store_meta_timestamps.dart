/// SQL триггеры для автоматического управления временными метками таблицы store_meta.
///
/// Эти триггеры автоматически устанавливают `created_at` и `modified_at`
/// при вставке и обновлении записей.
library;

/// Триггеры для установки временных меток при вставке.
const List<String> storeMetaInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_store_meta_timestamps
    AFTER INSERT ON store_meta
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE store_meta 
      SET 
        created_at = COALESCE(NEW.created_at, strftime('%s','now')  ),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now')  )
      WHERE id = NEW.id;
    END;
  ''',
];

/// Триггеры для обновления modified_at при изменении записи.
const List<String> storeMetaModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_store_meta_modified_at
    AFTER UPDATE ON store_meta
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE store_meta 
      SET modified_at = strftime('%s', 'now')  
      WHERE id = NEW.id;
    END;
  ''',
];

/// Операторы для удаления триггеров временных меток store_meta.
const List<String> storeMetaTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_store_meta_timestamps;',
  'DROP TRIGGER IF EXISTS update_store_meta_modified_at;',
];
