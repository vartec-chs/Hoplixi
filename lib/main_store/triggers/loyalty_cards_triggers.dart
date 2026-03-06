const List<String> loyaltyCardsHistoryCreateTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS loyalty_card_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'loyaltyCard' AND OLD.id = NEW.id AND (
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
        id, item_id, type, name, description, category_id, category_name,
        action, used_count, is_favorite, is_archived, is_pinned, is_deleted,
        recent_score, last_used_at, original_created_at, original_modified_at, action_at
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
      INSERT INTO loyalty_card_history (
        history_id, program_name, card_number, holder_name, barcode_value,
        barcode_type, points_balance, tier, expiry_date, website, phone_number
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        lci.program_name,
        lci.card_number,
        lci.holder_name,
        lci.barcode_value,
        lci.barcode_type,
        lci.points_balance,
        lci.tier,
        lci.expiry_date,
        lci.website,
        lci.phone_number
      FROM loyalty_card_items lci
      WHERE lci.item_id = OLD.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS loyalty_card_fields_update_history
    AFTER UPDATE ON loyalty_card_items
    FOR EACH ROW
    WHEN (
      OLD.program_name != NEW.program_name OR
      OLD.card_number != NEW.card_number OR
      OLD.holder_name IS NOT NEW.holder_name OR
      OLD.barcode_value IS NOT NEW.barcode_value OR
      OLD.barcode_type IS NOT NEW.barcode_type OR
      OLD.points_balance IS NOT NEW.points_balance OR
      OLD.tier IS NOT NEW.tier OR
      OLD.expiry_date IS NOT NEW.expiry_date OR
      OLD.website IS NOT NEW.website OR
      OLD.phone_number IS NOT NEW.phone_number
    ) AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id, item_id, type, name, description, category_id, category_name,
        action, used_count, is_favorite, is_archived, is_pinned, is_deleted,
        recent_score, last_used_at, original_created_at, original_modified_at, action_at
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

      INSERT INTO loyalty_card_history (
        history_id, program_name, card_number, holder_name, barcode_value,
        barcode_type, points_balance, tier, expiry_date, website, phone_number
      ) VALUES (
        (SELECT id FROM vault_item_history WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.program_name,
        OLD.card_number,
        OLD.holder_name,
        OLD.barcode_value,
        OLD.barcode_type,
        OLD.points_balance,
        OLD.tier,
        OLD.expiry_date,
        OLD.website,
        OLD.phone_number
      );
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS loyalty_card_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'loyaltyCard' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id, item_id, type, name, description, category_id, category_name,
        action, used_count, is_favorite, is_archived, is_pinned, is_deleted,
        recent_score, last_used_at, original_created_at, original_modified_at, action_at
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
      INSERT INTO loyalty_card_history (
        history_id, program_name, card_number, holder_name, barcode_value,
        barcode_type, points_balance, tier, expiry_date, website, phone_number
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        lci.program_name,
        lci.card_number,
        lci.holder_name,
        lci.barcode_value,
        lci.barcode_type,
        lci.points_balance,
        lci.tier,
        lci.expiry_date,
        lci.website,
        lci.phone_number
      FROM loyalty_card_items lci
      WHERE lci.item_id = OLD.id;
    END;
  ''',
];

const List<String> loyaltyCardsHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS loyalty_card_update_history;',
  'DROP TRIGGER IF EXISTS loyalty_card_fields_update_history;',
  'DROP TRIGGER IF EXISTS loyalty_card_delete_history;',
];
