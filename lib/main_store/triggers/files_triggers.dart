/// SQL триггеры для записи истории изменений файлов.
///
/// Эти триггеры автоматически создают записи в таблице `files_history`
/// при обновлении или удалении файлов.
const List<String> filesHistoryCreateTriggers = [
  // Триггер для записи истории при обновлении файла
  '''
    CREATE TRIGGER IF NOT EXISTS file_update_history
    AFTER UPDATE ON files
    FOR EACH ROW
    WHEN OLD.id = NEW.id AND (
      OLD.metadata_id != NEW.metadata_id OR
      OLD.name != NEW.name OR
      OLD.description != NEW.description OR
      OLD.note_id != NEW.note_id OR
      OLD.category_id != NEW.category_id OR
      OLD.is_favorite != NEW.is_favorite OR
      OLD.is_deleted != NEW.is_deleted OR
      OLD.is_archived != NEW.is_archived OR
      OLD.is_pinned != NEW.is_pinned OR
      OLD.recent_score != NEW.recent_score OR
      OLD.last_used_at != NEW.last_used_at
    )
    BEGIN
      INSERT INTO files_history (
        id,
        original_file_id,
        action,
        metadata_id,
        name,
        description,
        note_id,
        category_id,
        category_name,
        used_count,
        is_favorite,
        is_archived,
        is_pinned,
        recent_score,
        last_used_at,
        is_deleted,
        original_created_at,
        original_modified_at,
        original_last_used_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'modified',
        OLD.metadata_id,
        OLD.name,
        OLD.description,
        OLD.note_id,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        OLD.used_count,
        OLD.is_favorite,
        OLD.is_archived,
        OLD.is_pinned,
        OLD.recent_score,
        OLD.last_used_at,
        OLD.is_deleted,
        OLD.created_at,
        OLD.modified_at,
        OLD.last_used_at,
        strftime('%s','now')  
      );
    END;
  ''',
  // Триггер для записи истории при удалении файла
  '''
    CREATE TRIGGER IF NOT EXISTS file_delete_history
    BEFORE DELETE ON files
    FOR EACH ROW
    BEGIN
      INSERT INTO files_history (
        id,
        original_file_id,
        action,
        metadata_id,
        name,
        description,
        note_id,
        category_id,
        category_name,
        used_count,
        is_favorite,
        is_archived,
        is_pinned,
        recent_score,
        last_used_at,
        is_deleted,
        original_created_at,
        original_modified_at,
        original_last_used_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'deleted',
        OLD.metadata_id,
        OLD.name,
        OLD.description,
        OLD.note_id,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        OLD.used_count,
        OLD.is_favorite,
        OLD.is_archived,
        OLD.is_pinned,
        OLD.recent_score,
        OLD.last_used_at,
        OLD.is_deleted,
        OLD.created_at,
        OLD.modified_at,
        OLD.last_used_at,
        strftime('%s','now')  
      );
    END;
  ''',
];

/// Операторы для удаления триггеров истории файлов.
const List<String> filesHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS file_update_history;',
  'DROP TRIGGER IF EXISTS file_delete_history;',
];
