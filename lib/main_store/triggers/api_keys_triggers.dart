const List<String> apiKeysHistoryCreateTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS api_key_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'apiKey' AND OLD.id = NEW.id AND (
      OLD.name != NEW.name OR
      OLD.description IS NOT NEW.description OR
      OLD.note_id IS NOT NEW.note_id OR
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
        id, item_id, type, name, description, category_id, category_name,
        action, used_count, is_favorite, is_archived, is_pinned, is_deleted,
        recent_score, last_used_at, original_created_at, original_modified_at, action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id, OLD.type, OLD.name, OLD.description, OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        'modified', OLD.used_count, OLD.is_favorite, OLD.is_archived,
        OLD.is_pinned, OLD.is_deleted, OLD.recent_score, OLD.last_used_at,
        OLD.created_at, OLD.modified_at, strftime('%s','now')
      );

      INSERT INTO api_key_history (
        history_id, service, key, masked_key, token_type, environment, expires_at,
        revoked, rotation_period_days, last_rotated_at, metadata
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        a.service, a.key, a.masked_key, a.token_type, a.environment, a.expires_at,
        a.revoked, a.rotation_period_days, a.last_rotated_at, a.metadata
      FROM api_key_items a
      WHERE a.item_id = OLD.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS api_key_fields_update_history
    AFTER UPDATE ON api_key_items
    FOR EACH ROW
    WHEN (
      OLD.service != NEW.service OR
      OLD.key != NEW.key OR
      OLD.masked_key IS NOT NEW.masked_key OR
      OLD.token_type IS NOT NEW.token_type OR
      OLD.environment IS NOT NEW.environment OR
      OLD.expires_at IS NOT NEW.expires_at OR
      OLD.revoked != NEW.revoked OR
      OLD.rotation_period_days IS NOT NEW.rotation_period_days OR
      OLD.last_rotated_at IS NOT NEW.last_rotated_at OR
      OLD.metadata IS NOT NEW.metadata
    ) AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id, item_id, type, name, description, category_id, category_name,
        action, used_count, is_favorite, is_archived, is_pinned, is_deleted,
        recent_score, last_used_at, original_created_at, original_modified_at, action_at
      )
      SELECT
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        v.id, v.type, v.name, v.description, v.category_id,
        (SELECT name FROM categories WHERE id = v.category_id),
        'modified', v.used_count, v.is_favorite, v.is_archived, v.is_pinned,
        v.is_deleted, v.recent_score, v.last_used_at, v.created_at,
        v.modified_at, strftime('%s','now')
      FROM vault_items v
      WHERE v.id = OLD.item_id;

      INSERT INTO api_key_history (
        history_id, service, key, masked_key, token_type, environment, expires_at,
        revoked, rotation_period_days, last_rotated_at, metadata
      ) VALUES (
        (SELECT id FROM vault_item_history WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.service, OLD.key, OLD.masked_key, OLD.token_type, OLD.environment,
        OLD.expires_at, OLD.revoked, OLD.rotation_period_days,
        OLD.last_rotated_at, OLD.metadata
      );
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS api_key_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'apiKey' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id, item_id, type, name, description, category_id, category_name,
        action, used_count, is_favorite, is_archived, is_pinned, is_deleted,
        recent_score, last_used_at, original_created_at, original_modified_at, action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id, OLD.type, OLD.name, OLD.description, OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        'deleted', OLD.used_count, OLD.is_favorite, OLD.is_archived,
        OLD.is_pinned, OLD.is_deleted, OLD.recent_score, OLD.last_used_at,
        OLD.created_at, OLD.modified_at, strftime('%s','now')
      );

      INSERT INTO api_key_history (
        history_id, service, key, masked_key, token_type, environment, expires_at,
        revoked, rotation_period_days, last_rotated_at, metadata
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        a.service, a.key, a.masked_key, a.token_type, a.environment, a.expires_at,
        a.revoked, a.rotation_period_days, a.last_rotated_at, a.metadata
      FROM api_key_items a
      WHERE a.item_id = OLD.id;
    END;
  ''',
];

const List<String> apiKeysHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS api_key_update_history;',
  'DROP TRIGGER IF EXISTS api_key_fields_update_history;',
  'DROP TRIGGER IF EXISTS api_key_delete_history;',
];
