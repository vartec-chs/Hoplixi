/// SQL триггеры для автоматического удаления связанных страниц при удалении документа.
///
/// Эти триггеры обеспечивают каскадное удаление страниц документа и связанных файлов.
const List<String> documentsDeleteTriggers = [
  // Триггер для удаления связанных страниц при удалении документа
  '''
    CREATE TRIGGER IF NOT EXISTS document_delete_cascade_pages
    BEFORE DELETE ON documents
    FOR EACH ROW
    BEGIN
      -- Удаляем связанные страницы (это также удалит связанные файлы через их триггеры)
      DELETE FROM document_pages WHERE document_id = OLD.id;
    END;
  ''',
];

/// Операторы для удаления триггеров документов.
const List<String> documentsDropTriggers = [
  'DROP TRIGGER IF EXISTS document_delete_cascade_pages;',
];
