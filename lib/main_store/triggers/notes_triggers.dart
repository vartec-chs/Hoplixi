/// SQL триггеры для записи истории изменений заметок.
///
/// Эти триггеры автоматически создают записи в таблице `notes_history`
/// при обновлении или удалении заметок.
const List<String> notesHistoryCreateTriggers = [
  // Триггер для записи истории при обновлении заметки
  '''
    CREATE TRIGGER IF NOT EXISTS note_update_history
    AFTER UPDATE ON notes
    FOR EACH ROW
    WHEN OLD.id = NEW.id AND (
      OLD.title != NEW.title OR
      OLD.description != NEW.description OR
      OLD.delta_json != NEW.delta_json OR
      OLD.content != NEW.content OR
      OLD.category_id != NEW.category_id OR
      OLD.is_favorite != NEW.is_favorite OR
      OLD.is_deleted != NEW.is_deleted OR
      OLD.is_archived != NEW.is_archived OR
      OLD.is_pinned != NEW.is_pinned OR
      OLD.recent_score != NEW.recent_score OR
      OLD.last_used_at != NEW.last_used_at
    )
    BEGIN
      INSERT INTO notes_history (
        id,
        original_note_id,
        action,
        title,
        description,
        delta_json,
        content,
        category_id,
        category_name,
        used_count,
        is_favorite,
        is_deleted,
        is_archived,
        is_pinned,
        recent_score,
        last_used_at,
        original_created_at,
        original_modified_at,
        original_last_used_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'modified',
        OLD.title,
        OLD.description,
        OLD.delta_json,
        OLD.content,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        OLD.used_count,
        OLD.is_favorite,
        OLD.is_deleted,
        OLD.is_archived,
        OLD.is_pinned,
        OLD.recent_score,
        OLD.last_used_at,
        OLD.created_at,
        OLD.modified_at,
        OLD.last_used_at,
        strftime('%s','now')  
      );
    END;
  ''',
  // Триггер для записи истории при удалении заметки
  '''
    CREATE TRIGGER IF NOT EXISTS note_delete_history
    BEFORE DELETE ON notes
    FOR EACH ROW
    BEGIN
      INSERT INTO notes_history (
        id,
        original_note_id,
        action,
        title,
        description,
        delta_json,
        content,
        category_id,
        category_name,
        used_count,
        is_favorite,
        is_deleted,
        is_archived,
        is_pinned,
        recent_score,
        last_used_at,
        original_created_at,
        original_modified_at,
        original_last_used_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'deleted',
        OLD.title,
        OLD.description,
        OLD.delta_json,
        OLD.content,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        OLD.used_count,
        OLD.is_favorite,
        OLD.is_deleted,
        OLD.is_archived,
        OLD.is_pinned,
        OLD.recent_score,
        OLD.last_used_at,
        OLD.created_at,
        OLD.modified_at,
        OLD.last_used_at,
        strftime('%s','now')  
      );
    END;
  ''',
];

/// Операторы для удаления триггеров истории заметок.
const List<String> notesHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS note_update_history;',
  'DROP TRIGGER IF EXISTS note_delete_history;',
];
