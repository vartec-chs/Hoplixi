/// SQL триггеры для записи истории изменений паролей.
///
/// Эти триггеры автоматически создают записи в таблице `passwords_history`
/// при обновлении или удалении паролей.
const List<String> passwordsHistoryCreateTriggers = [
  // Триггер для записи истории при обновлении пароля
  '''
    CREATE TRIGGER IF NOT EXISTS password_update_history
    AFTER UPDATE ON passwords
    FOR EACH ROW
    WHEN OLD.id = NEW.id AND (
      OLD.name != NEW.name OR
      OLD.description != NEW.description OR
      OLD.password != NEW.password OR
      OLD.url != NEW.url OR
      OLD.notes != NEW.notes OR
      OLD.login != NEW.login OR
      OLD.email != NEW.email OR
      OLD.category_id != NEW.category_id OR
      OLD.is_favorite != NEW.is_favorite OR
      OLD.is_deleted != NEW.is_deleted OR
      OLD.is_archived != NEW.is_archived OR
      OLD.is_pinned != NEW.is_pinned OR
      OLD.recent_score != NEW.recent_score OR
      OLD.last_used_at != NEW.last_used_at
    )
    BEGIN
      INSERT INTO passwords_history (
        id,
        original_password_id,
        action,
        name,
        description,
        password,
        url,
        notes,
        login,
        email,
        category_id,
        category_name,
        tags,
        used_count,
        is_archived,
        is_pinned,
        is_favorite,
        is_deleted,
        last_accessed_at,
        original_created_at,
        original_modified_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'modified',
        OLD.name,
        OLD.description,
        OLD.password,
        OLD.url,
        OLD.notes,
        OLD.login,
        OLD.email,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        (SELECT json_group_array(t.name) FROM tags t 
         JOIN password_tags pt ON t.id = pt.tag_id 
         WHERE pt.password_id = OLD.id),
        OLD.used_count,
        OLD.is_archived,
        OLD.is_pinned,
        OLD.is_favorite,
        OLD.recent_score,
        OLD.last_used_at,
        OLD.is_deleted,
        OLD.last_used_at,
        OLD.created_at,
        OLD.modified_at,
        strftime('%s','now')  
      );
    END;
  ''',
  // Триггер для записи истории при удалении пароля
  '''
    CREATE TRIGGER IF NOT EXISTS password_delete_history
    BEFORE DELETE ON passwords
    FOR EACH ROW
    BEGIN
      INSERT INTO passwords_history (
        id,
        original_password_id,
        action,
        name,
        description,
        password,
        url,
        notes,
        login,
        email,
        category_id,
        category_name,
        tags,
        used_count,
        is_archived,
        is_pinned,
        is_favorite,
        is_deleted,
        last_accessed_at,
        original_created_at,
        original_modified_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'deleted',
        OLD.name,
        OLD.description,
        OLD.password,
        OLD.url,
        OLD.notes,
        OLD.login,
        OLD.email,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        (SELECT json_group_array(t.name) FROM tags t 
         JOIN password_tags pt ON t.id = pt.tag_id 
         WHERE pt.password_id = OLD.id),
        OLD.used_count,
        OLD.is_archived,
        OLD.is_pinned,
        OLD.is_favorite,
        OLD.recent_score,
        OLD.last_used_at,
        OLD.is_deleted,
        OLD.last_used_at,
        OLD.created_at,
        OLD.modified_at,
        strftime('%s','now')  
      );
    END;
  ''',
];

/// Операторы для удаления триггеров истории паролей.
const List<String> passwordsHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS password_update_history;',
  'DROP TRIGGER IF EXISTS password_delete_history;',
];
