/// SQL-триггеры для временных меток таблиц версий документов.
library;

const List<String> documentVersionsInsertTimestampTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS insert_document_versions_timestamps
    AFTER INSERT ON document_versions
    FOR EACH ROW
    WHEN NEW.created_at IS NULL OR NEW.modified_at IS NULL
    BEGIN
      UPDATE document_versions
      SET
        created_at = COALESCE(NEW.created_at, strftime('%s','now')),
        modified_at = COALESCE(NEW.modified_at, strftime('%s','now'))
      WHERE id = NEW.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS insert_document_version_pages_timestamps
    AFTER INSERT ON document_version_pages
    FOR EACH ROW
    WHEN NEW.created_at IS NULL
    BEGIN
      UPDATE document_version_pages
      SET
        created_at = COALESCE(NEW.created_at, strftime('%s','now'))
      WHERE id = NEW.id;
    END;
  ''',
];

const List<String> documentVersionsModifiedAtTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS update_document_versions_modified_at
    AFTER UPDATE ON document_versions
    FOR EACH ROW
    WHEN NEW.modified_at = OLD.modified_at
    BEGIN
      UPDATE document_versions
      SET modified_at = strftime('%s', 'now')
      WHERE id = NEW.id;
    END;
  ''',
];

const List<String> documentVersionsTimestampDropTriggers = [
  'DROP TRIGGER IF EXISTS insert_document_versions_timestamps;',
  'DROP TRIGGER IF EXISTS update_document_versions_modified_at;',
  'DROP TRIGGER IF EXISTS insert_document_version_pages_timestamps;',
  'DROP TRIGGER IF EXISTS update_document_version_pages_modified_at;',
];
