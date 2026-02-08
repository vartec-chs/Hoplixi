/// SQL триггеры для автоматического управления временными метками таблицы otps.
///
/// Эти триггеры автоматически устанавливают `created_at` и `modified_at`
/// при вставке и обновлении записей.
library;

/// Триггеры для установки временных меток при вставке.
const List<String> otpsInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_otps_timestamps
    AFTER INSERT ON otps
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE otps 
      SET 
        created_at = COALESCE(NEW.created_at, strftime('%s','now')  ),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now')  )
      WHERE id = NEW.id;
    END;
  ''',
];

/// Триггеры для обновления modified_at при изменении записи.
const List<String> otpsModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_otps_modified_at
    AFTER UPDATE ON otps
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE otps 
      SET modified_at = strftime('%s', 'now')  
      WHERE id = NEW.id;
    END;
  ''',
];

/// Операторы для удаления триггеров временных меток otps.
const List<String> otpsTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_otps_timestamps;',
  'DROP TRIGGER IF EXISTS update_otps_modified_at;',
];
