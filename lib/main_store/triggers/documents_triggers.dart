/// SQL триггеры для каскадных операций с документами.
///
/// Эти триггеры обеспечивают целостность данных при удалении и обновлении
/// документов и их страниц, включая очистку метаданных файлов.
const List<String> documentsTriggers = [
  // Триггер для удаления связанных страниц при удалении документа
  '''
    CREATE TRIGGER IF NOT EXISTS document_delete_cascade_pages
    BEFORE DELETE ON documents
    FOR EACH ROW
    BEGIN
      -- Удаляем связанные страницы (это запустит document_page_delete_cleanup)
      DELETE FROM document_pages WHERE document_id = OLD.id;
    END;
  ''',

  // Триггер для удаления метаданных файла при удалении страницы
  '''
    CREATE TRIGGER IF NOT EXISTS document_page_delete_cleanup
    AFTER DELETE ON document_pages
    FOR EACH ROW
    WHEN OLD.metadata_id IS NOT NULL
    BEGIN
      -- Удаляем метаданные, так как страница удалена
      DELETE FROM file_metadata WHERE id = OLD.metadata_id;
    END;
  ''',

  // Триггер для удаления старых метаданных файла при обновлении страницы
  '''
    CREATE TRIGGER IF NOT EXISTS document_page_update_cleanup
    AFTER UPDATE ON document_pages
    FOR EACH ROW
    WHEN OLD.metadata_id IS NOT NULL AND (NEW.metadata_id IS NULL OR OLD.metadata_id != NEW.metadata_id)
    BEGIN
      -- Удаляем старые метаданные, так как ссылка на них изменилась или удалена
      DELETE FROM file_metadata WHERE id = OLD.metadata_id;
    END;
  ''',
];

/// Операторы для удаления триггеров документов.
const List<String> documentsDropTriggers = [
  'DROP TRIGGER IF EXISTS document_delete_cascade_pages;',
  'DROP TRIGGER IF EXISTS document_page_delete_cleanup;',
  'DROP TRIGGER IF EXISTS document_page_update_cleanup;',
];
