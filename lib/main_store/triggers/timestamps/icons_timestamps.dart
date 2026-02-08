/// SQL триггеры для автоматического управления временными метками таблицы icons.
///
/// Эти триггеры автоматически устанавливают `created_at` и `modified_at`
/// при вставке и обновлении записей.
library;

/// Триггеры для установки временных меток при вставке.
const List<String> iconsInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_icons_timestamps
    AFTER INSERT ON icons
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE icons 
      SET 
        created_at = COALESCE(NEW.created_at, strftime('%s','now')  ),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now')  )
      WHERE id = NEW.id;
    END;
  ''',
];

/// Триггеры для обновления modified_at при изменении записи.
const List<String> iconsModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_icons_modified_at
    AFTER UPDATE ON icons
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE icons 
      SET modified_at = strftime('%s', 'now')  
      WHERE id = NEW.id;
    END;
  ''',
];

/// Операторы для удаления триггеров временных меток icons.
const List<String> iconsTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_icons_timestamps;',
  'DROP TRIGGER IF EXISTS update_icons_modified_at;',
];
