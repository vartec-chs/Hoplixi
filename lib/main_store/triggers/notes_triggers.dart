/// SQL триггеры для записи истории изменений заметок.
///
/// Триггеры срабатывают на таблице `vault_items` (для строк с type = 'note')
/// и вставляют записи в `vault_item_history` + `note_history`.
/// Дополнительный триггер на `note_items` отслеживает изменения
/// специфичных полей: delta_json, content.
const List<String> notesHistoryCreateTriggers = [
  // Триггер для записи истории при обновлении общих полей заметки
  '''
    CREATE TRIGGER IF NOT EXISTS note_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'note' AND OLD.id = NEW.id AND (
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
      INSERT INTO note_history (
        history_id,
        delta_json,
        content
      )
      SELECT
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        ni.delta_json,
        ni.content
      FROM note_items ni
      WHERE ni.item_id = OLD.id;
    END;
  ''',

  // Триггер для записи истории при изменении контента заметки (delta_json / content)
  '''
    CREATE TRIGGER IF NOT EXISTS note_content_update_history
    AFTER UPDATE ON note_items
    FOR EACH ROW
    WHEN (
      OLD.delta_json != NEW.delta_json OR
      OLD.content != NEW.content
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

      INSERT INTO note_history (
        history_id,
        delta_json,
        content
      ) VALUES (
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.delta_json,
        OLD.content
      );
    END;
  ''',

  // Триггер для записи истории при удалении заметки
  '''
    CREATE TRIGGER IF NOT EXISTS note_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'note' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
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
      INSERT INTO note_history (
        history_id,
        delta_json,
        content
      )
      SELECT
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        ni.delta_json,
        ni.content
      FROM note_items ni
      WHERE ni.item_id = OLD.id;
    END;
  ''',
];

/// Операторы для удаления триггеров истории заметок.
const List<String> notesHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS note_update_history;',
  'DROP TRIGGER IF EXISTS note_content_update_history;',
  'DROP TRIGGER IF EXISTS note_delete_history;',
];
