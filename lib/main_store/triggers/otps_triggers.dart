/// SQL триггеры для записи истории изменений OTP-кодов.
///
/// Триггеры срабатывают на таблице `vault_items` (для строк с type = 'otp')
/// и вставляют записи в `vault_item_history` + `otp_history`.
const List<String> otpsHistoryCreateTriggers = [
  // Триггер для записи истории при обновлении OTP
  '''
    CREATE TRIGGER IF NOT EXISTS otp_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'otp' AND OLD.id = NEW.id AND (
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
      INSERT INTO otp_history (
        history_id,
        password_item_id,
        type,
        issuer,
        account_name,
        secret,
        secret_encoding,
        algorithm,
        digits,
        period,
        counter
      )
      SELECT
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        oi.password_item_id,
        oi.type,
        oi.issuer,
        oi.account_name,
        oi.secret,
        oi.secret_encoding,
        oi.algorithm,
        oi.digits,
        oi.period,
        oi.counter
      FROM otp_items oi
      WHERE oi.item_id = OLD.id;
    END;
  ''',
  // Триггер для записи истории при удалении OTP
  '''
    CREATE TRIGGER IF NOT EXISTS otp_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'otp' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
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
      INSERT INTO otp_history (
        history_id,
        password_item_id,
        type,
        issuer,
        account_name,
        secret,
        secret_encoding,
        algorithm,
        digits,
        period,
        counter
      )
      SELECT
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        oi.password_item_id,
        oi.type,
        oi.issuer,
        oi.account_name,
        oi.secret,
        oi.secret_encoding,
        oi.algorithm,
        oi.digits,
        oi.period,
        oi.counter
      FROM otp_items oi
      WHERE oi.item_id = OLD.id;
    END;
  ''',
];

/// Операторы для удаления триггеров истории OTP.
const List<String> otpsHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS otp_update_history;',
  'DROP TRIGGER IF EXISTS otp_delete_history;',
];
