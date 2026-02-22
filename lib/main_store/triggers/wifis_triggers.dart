const List<String> wifisHistoryCreateTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS wifi_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'wifi' AND OLD.id = NEW.id AND (
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

      INSERT INTO wifi_history (
        history_id, ssid, password, security, hidden,
        eap_method, username, identity, domain,
        last_connected_bssid, priority, notes, qr_code_payload
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        w.ssid, w.password, w.security, w.hidden,
        w.eap_method, w.username, w.identity, w.domain,
        w.last_connected_bssid, w.priority, w.notes, w.qr_code_payload
      FROM wifi_items w
      WHERE w.item_id = OLD.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS wifi_fields_update_history
    AFTER UPDATE ON wifi_items
    FOR EACH ROW
    WHEN (
      OLD.ssid != NEW.ssid OR
      OLD.password IS NOT NEW.password OR
      OLD.security IS NOT NEW.security OR
      OLD.hidden != NEW.hidden OR
      OLD.eap_method IS NOT NEW.eap_method OR
      OLD.username IS NOT NEW.username OR
      OLD.identity IS NOT NEW.identity OR
      OLD.domain IS NOT NEW.domain OR
      OLD.last_connected_bssid IS NOT NEW.last_connected_bssid OR
      OLD.priority IS NOT NEW.priority OR
      OLD.notes IS NOT NEW.notes OR
      OLD.qr_code_payload IS NOT NEW.qr_code_payload
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

      INSERT INTO wifi_history (
        history_id, ssid, password, security, hidden,
        eap_method, username, identity, domain,
        last_connected_bssid, priority, notes, qr_code_payload
      ) VALUES (
        (SELECT id FROM vault_item_history WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.ssid, OLD.password, OLD.security, OLD.hidden,
        OLD.eap_method, OLD.username, OLD.identity, OLD.domain,
        OLD.last_connected_bssid, OLD.priority, OLD.notes, OLD.qr_code_payload
      );
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS wifi_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'wifi' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
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

      INSERT INTO wifi_history (
        history_id, ssid, password, security, hidden,
        eap_method, username, identity, domain,
        last_connected_bssid, priority, notes, qr_code_payload
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        w.ssid, w.password, w.security, w.hidden,
        w.eap_method, w.username, w.identity, w.domain,
        w.last_connected_bssid, w.priority, w.notes, w.qr_code_payload
      FROM wifi_items w
      WHERE w.item_id = OLD.id;
    END;
  ''',
];

const List<String> wifisHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS wifi_update_history;',
  'DROP TRIGGER IF EXISTS wifi_fields_update_history;',
  'DROP TRIGGER IF EXISTS wifi_delete_history;',
];
