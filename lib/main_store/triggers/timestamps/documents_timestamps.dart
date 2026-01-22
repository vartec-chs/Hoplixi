/// SQL триггеры для автоматического управления временными метками таблицы documents.
///
/// Эти триггеры автоматически устанавливают `created_at` и `modified_at`
/// при вставке и обновлении записей.

/// Триггеры для установки временных меток при вставке.
const List<String> documentsInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_documents_timestamps
    AFTER INSERT ON documents
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE documents 
      SET 
        created_at = COALESCE(NEW.created_at, strftime('%s','now')  ),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now')  )
      WHERE id = NEW.id;
    END;
  ''',
];

/// Триггеры для обновления modified_at при изменении записи.
const List<String> documentsModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_documents_modified_at
    AFTER UPDATE ON documents
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE documents 
      SET modified_at = strftime('%s', 'now')  
      WHERE id = NEW.id;
    END;
  ''',
];

/// Операторы для удаления триггеров временных меток documents.
const List<String> documentsTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_documents_timestamps;',
  'DROP TRIGGER IF EXISTS update_documents_modified_at;',
];
