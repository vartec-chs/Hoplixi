/// SQL триггеры для записи истории изменений OTP-кодов.
///
/// Эти триггеры автоматически создают записи в таблице `otps_history`
/// при обновлении или удалении OTP-кодов.
const List<String> otpsHistoryCreateTriggers = [
  // Триггер для записи истории при обновлении OTP
  '''
    CREATE TRIGGER IF NOT EXISTS otp_update_history
    AFTER UPDATE ON otps
    FOR EACH ROW
    WHEN OLD.id = NEW.id AND (
      OLD.type != NEW.type OR
      OLD.issuer != NEW.issuer OR
      OLD.account_name != NEW.account_name OR
      OLD.secret != NEW.secret OR
      OLD.secret_encoding != NEW.secret_encoding OR
      OLD.notes != NEW.notes OR
      OLD.algorithm != NEW.algorithm OR
      OLD.digits != NEW.digits OR
      OLD.period != NEW.period OR
      OLD.counter != NEW.counter OR
      OLD.password_id != NEW.password_id OR
      OLD.category_id != NEW.category_id OR
      OLD.is_favorite != NEW.is_favorite OR
      OLD.is_deleted != NEW.is_deleted OR
      OLD.is_archived != NEW.is_archived OR
      OLD.is_pinned != NEW.is_pinned
    )
    BEGIN
      INSERT INTO otps_history (
        id,
        original_otp_id,
        action,
        type,
        issuer,
        account_name,
        secret,
        secret_encoding,
        notes,
        algorithm,
        digits,
        period,
        counter,
        password_id,
        category_id,
        category_name,
        used_count,
        is_favorite,
        is_pinned,
        original_created_at,
        original_modified_at,
        original_last_accessed_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'modified',
        OLD.type,
        OLD.issuer,
        OLD.account_name,
        OLD.secret,
        OLD.secret_encoding,
        OLD.notes,
        OLD.algorithm,
        OLD.digits,
        OLD.period,
        OLD.counter,
        OLD.password_id,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        OLD.used_count,
        OLD.is_favorite,
        OLD.is_pinned,
        OLD.created_at,
        OLD.modified_at,
        OLD.last_accessed_at,
        strftime('%s','now')  
      );
    END;
  ''',
  // Триггер для записи истории при удалении OTP
  '''
    CREATE TRIGGER IF NOT EXISTS otp_delete_history
    BEFORE DELETE ON otps
    FOR EACH ROW
    BEGIN
      INSERT INTO otps_history (
        id,
        original_otp_id,
        action,
        type,
        issuer,
        account_name,
        secret,
        secret_encoding,
        notes,
        algorithm,
        digits,
        period,
        counter,
        password_id,
        category_id,
        category_name,
        used_count,
        is_favorite,
        is_pinned,
        original_created_at,
        original_modified_at,
        original_last_accessed_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'deleted',
        OLD.type,
        OLD.issuer,
        OLD.account_name,
        OLD.secret,
        OLD.secret_encoding,
        OLD.notes,
        OLD.algorithm,
        OLD.digits,
        OLD.period,
        OLD.counter,
        OLD.password_id,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        OLD.used_count,
        OLD.is_favorite,
        OLD.is_pinned,
        OLD.created_at,
        OLD.modified_at,
        OLD.last_accessed_at,
        strftime('%s','now')  
      );
    END;
  ''',
];

/// Операторы для удаления триггеров истории OTP.
const List<String> otpsHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS otp_update_history;',
  'DROP TRIGGER IF EXISTS otp_delete_history;',
];
