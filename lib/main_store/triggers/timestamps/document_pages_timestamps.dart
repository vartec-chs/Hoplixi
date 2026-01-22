/// SQL триггеры для автоматического управления временными метками таблицы document_pages.
///
/// Эти триггеры автоматически устанавливают `created_at` и `modified_at`
/// при вставке и обновлении записей.

/// Триггеры для установки временных меток при вставке.
const List<String> documentPagesInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_document_pages_timestamps
    AFTER INSERT ON document_pages
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE document_pages 
      SET 
        created_at = COALESCE(NEW.created_at, strftime('%s','now')  ),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now')  )
      WHERE id = NEW.id;
    END;
  ''',
];

/// Триггеры для обновления modified_at при изменении записи.
const List<String> documentPagesModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_document_pages_modified_at
    AFTER UPDATE ON document_pages
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE document_pages 
      SET modified_at = strftime('%s', 'now')  
      WHERE id = NEW.id;
    END;
  ''',
];

/// Операторы для удаления триггеров временных меток document_pages.
const List<String> documentPagesTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_document_pages_timestamps;',
  'DROP TRIGGER IF EXISTS update_document_pages_modified_at;',
];
