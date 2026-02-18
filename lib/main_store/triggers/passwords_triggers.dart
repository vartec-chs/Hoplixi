/// SQL триггеры для записи истории изменений паролей.
///
/// Триггеры срабатывают на таблице `vault_items` (для строк с type = 'password')
/// и вставляют записи в `vault_item_history` + `password_history`.
const List<String> passwordsHistoryCreateTriggers = [
  // Триггер для записи истории при обновлении пароля
  '''
    CREATE TRIGGER IF NOT EXISTS password_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'password' AND OLD.id = NEW.id AND (
      OLD.name != NEW.name OR
      OLD.description IS NOT NEW.description OR
      OLD.note_id IS NOT NEW.note_id OR
      OLD.category_id IS NOT NEW.category_id OR
      OLD.is_favorite != NEW.is_favorite OR
      OLD.is_deleted != NEW.is_deleted OR
      OLD.is_archived != NEW.is_archived OR
      OLD.is_pinned != NEW.is_pinned OR
      OLD.recent_score IS NOT NEW.recent_score OR
      OLD.last_used_at IS NOT NEW.last_used_at OR
      EXISTS (
        SELECT 1 FROM password_items pi
        WHERE pi.item_id = OLD.id AND (
          pi.login IS NOT (SELECT login FROM password_items WHERE item_id = OLD.id) OR
          pi.email IS NOT (SELECT email FROM password_items WHERE item_id = OLD.id) OR
          pi.password != (SELECT password FROM password_items WHERE item_id = OLD.id) OR
          pi.url IS NOT (SELECT url FROM password_items WHERE item_id = OLD.id)
        )
      )
    )
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
      INSERT INTO password_history (
        history_id,
        login,
        email,
        password,
        url
      )
      SELECT
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        pi.login,
        pi.email,
        pi.password,
        pi.url
      FROM password_items pi
      WHERE pi.item_id = OLD.id;
    END;
  ''',
  // Триггер для записи истории при удалении пароля
  '''
    CREATE TRIGGER IF NOT EXISTS password_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'password'
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
      INSERT INTO password_history (
        history_id,
        login,
        email,
        password,
        url
      )
      SELECT
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        pi.login,
        pi.email,
        pi.password,
        pi.url
      FROM password_items pi
      WHERE pi.item_id = OLD.id;
    END;
  ''',
];

/// Операторы для удаления триггеров истории паролей.
const List<String> passwordsHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS password_update_history;',
  'DROP TRIGGER IF EXISTS password_delete_history;',
];
