const List<String> licenseKeysHistoryCreateTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS license_key_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'licenseKey' AND OLD.id = NEW.id AND (
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

      INSERT INTO license_key_history (
        history_id, product, license_key, license_type, seats, max_activations,
        activated_on, purchase_date, purchase_from, order_id, license_file_id,
        expires_at, support_contact
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        l.product, l.license_key, l.license_type, l.seats, l.max_activations,
        l.activated_on, l.purchase_date, l.purchase_from, l.order_id,
        l.license_file_id, l.expires_at, l.support_contact
      FROM license_key_items l
      WHERE l.item_id = OLD.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS license_key_fields_update_history
    AFTER UPDATE ON license_key_items
    FOR EACH ROW
    WHEN (
      OLD.product != NEW.product OR
      OLD.license_key != NEW.license_key OR
      OLD.license_type IS NOT NEW.license_type OR
      OLD.seats IS NOT NEW.seats OR
      OLD.max_activations IS NOT NEW.max_activations OR
      OLD.activated_on IS NOT NEW.activated_on OR
      OLD.purchase_date IS NOT NEW.purchase_date OR
      OLD.purchase_from IS NOT NEW.purchase_from OR
      OLD.order_id IS NOT NEW.order_id OR
      OLD.license_file_id IS NOT NEW.license_file_id OR
      OLD.expires_at IS NOT NEW.expires_at OR
      OLD.support_contact IS NOT NEW.support_contact
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

      INSERT INTO license_key_history (
        history_id, product, license_key, license_type, seats, max_activations,
        activated_on, purchase_date, purchase_from, order_id, license_file_id,
        expires_at, support_contact
      ) VALUES (
        (SELECT id FROM vault_item_history WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.product, OLD.license_key, OLD.license_type, OLD.seats,
        OLD.max_activations, OLD.activated_on, OLD.purchase_date,
        OLD.purchase_from, OLD.order_id, OLD.license_file_id, OLD.expires_at,
        OLD.support_contact
      );
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS license_key_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'licenseKey' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
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

      INSERT INTO license_key_history (
        history_id, product, license_key, license_type, seats, max_activations,
        activated_on, purchase_date, purchase_from, order_id, license_file_id,
        expires_at, support_contact
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        l.product, l.license_key, l.license_type, l.seats, l.max_activations,
        l.activated_on, l.purchase_date, l.purchase_from, l.order_id,
        l.license_file_id, l.expires_at, l.support_contact
      FROM license_key_items l
      WHERE l.item_id = OLD.id;
    END;
  ''',
];

const List<String> licenseKeysHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS license_key_update_history;',
  'DROP TRIGGER IF EXISTS license_key_fields_update_history;',
  'DROP TRIGGER IF EXISTS license_key_delete_history;',
];
