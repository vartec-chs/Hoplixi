/// SQL триггеры для документов.
///
/// Включает:
/// - Триггеры истории изменений (vault_items → vault_item_history + document_history)
/// - Триггер на document_items для детекта изменений специфичных полей
/// - Каскадные триггеры для очистки метаданных страниц документа
const List<String> documentsHistoryCreateTriggers = [
  // Триггер для записи истории при обновлении общих полей документа
  '''
    CREATE TRIGGER IF NOT EXISTS document_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'document' AND OLD.id = NEW.id AND (
      OLD.name != NEW.name OR
      OLD.description IS NOT NEW.description OR
      OLD.category_id IS NOT NEW.category_id OR
      OLD.is_favorite != NEW.is_favorite OR
      OLD.is_deleted != NEW.is_deleted OR
      OLD.is_archived != NEW.is_archived OR
      OLD.is_pinned != NEW.is_pinned OR
      OLD.recent_score IS NOT NEW.recent_score OR
      OLD.last_used_at IS NOT NEW.last_used_at
    ) AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id,
        item_id,
        type,
        name,
        description,
        category_id,
        category_name,
        action,
        used_count,
        is_favorite,
        is_archived,
        is_pinned,
        is_deleted,
        recent_score,
        last_used_at,
        original_created_at,
        original_modified_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        OLD.type,
        OLD.name,
        OLD.description,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        'modified',
        OLD.used_count,
        OLD.is_favorite,
        OLD.is_archived,
        OLD.is_pinned,
        OLD.is_deleted,
        OLD.recent_score,
        OLD.last_used_at,
        OLD.created_at,
        OLD.modified_at,
        strftime('%s','now')
      );
      INSERT INTO document_history (
        history_id,
        document_type,
        aggregated_text,
        aggregate_hash,
        page_count
      )
      SELECT
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        di.document_type,
        di.aggregated_text,
        di.aggregate_hash,
        di.page_count
      FROM document_items di
      WHERE di.item_id = OLD.id;
    END;
  ''',

  // Триггер для записи истории при изменении специфичных полей документа
  // (document_type, aggregated_text, aggregate_hash, page_count)
  '''
    CREATE TRIGGER IF NOT EXISTS document_fields_update_history
    AFTER UPDATE ON document_items
    FOR EACH ROW
    WHEN (
      OLD.document_type IS NOT NEW.document_type OR
      OLD.aggregated_text IS NOT NEW.aggregated_text OR
      OLD.aggregate_hash IS NOT NEW.aggregate_hash OR
      OLD.page_count != NEW.page_count
    ) AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id,
        item_id,
        type,
        name,
        description,
        category_id,
        category_name,
        action,
        used_count,
        is_favorite,
        is_archived,
        is_pinned,
        is_deleted,
        recent_score,
        last_used_at,
        original_created_at,
        original_modified_at,
        action_at
      )
      SELECT
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        v.id,
        v.type,
        v.name,
        v.description,
        v.category_id,
        (SELECT name FROM categories WHERE id = v.category_id),
        'modified',
        v.used_count,
        v.is_favorite,
        v.is_archived,
        v.is_pinned,
        v.is_deleted,
        v.recent_score,
        v.last_used_at,
        v.created_at,
        v.modified_at,
        strftime('%s','now')
      FROM vault_items v
      WHERE v.id = OLD.item_id;

      INSERT INTO document_history (
        history_id,
        document_type,
        aggregated_text,
        aggregate_hash,
        page_count
      ) VALUES (
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.document_type,
        OLD.aggregated_text,
        OLD.aggregate_hash,
        OLD.page_count
      );
    END;
  ''',

  // Триггер для записи истории при удалении документа
  '''
    CREATE TRIGGER IF NOT EXISTS document_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'document' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id,
        item_id,
        type,
        name,
        description,
        category_id,
        category_name,
        action,
        used_count,
        is_favorite,
        is_archived,
        is_pinned,
        is_deleted,
        recent_score,
        last_used_at,
        original_created_at,
        original_modified_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        OLD.type,
        OLD.name,
        OLD.description,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        'deleted',
        OLD.used_count,
        OLD.is_favorite,
        OLD.is_archived,
        OLD.is_pinned,
        OLD.is_deleted,
        OLD.recent_score,
        OLD.last_used_at,
        OLD.created_at,
        OLD.modified_at,
        strftime('%s','now')
      );
      INSERT INTO document_history (
        history_id,
        document_type,
        aggregated_text,
        aggregate_hash,
        page_count
      )
      SELECT
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        di.document_type,
        di.aggregated_text,
        di.aggregate_hash,
        di.page_count
      FROM document_items di
      WHERE di.item_id = OLD.id;
    END;
  ''',
];

/// Каскадные триггеры для очистки метаданных страниц документа.
///
/// `document_pages.document_id` ссылается на `vault_items.id` с CASCADE,
/// поэтому страницы удаляются автоматически. Эти триггеры обеспечивают
/// дополнительную очистку `file_metadata`.
const List<String> documentsTriggers = [
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
    WHEN OLD.metadata_id IS NOT NULL
      AND (NEW.metadata_id IS NULL OR OLD.metadata_id != NEW.metadata_id)
    BEGIN
      -- Удаляем старые метаданные, так как ссылка изменилась или удалена
      DELETE FROM file_metadata WHERE id = OLD.metadata_id;
    END;
  ''',
];

/// Операторы для удаления триггеров документов.
const List<String> documentsDropTriggers = [
  'DROP TRIGGER IF EXISTS document_update_history;',
  'DROP TRIGGER IF EXISTS document_fields_update_history;',
  'DROP TRIGGER IF EXISTS document_delete_history;',
  'DROP TRIGGER IF EXISTS document_page_delete_cleanup;',
  'DROP TRIGGER IF EXISTS document_page_update_cleanup;',
];
