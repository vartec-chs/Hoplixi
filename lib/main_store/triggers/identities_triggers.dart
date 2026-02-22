const List<String> identitiesHistoryCreateTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS identity_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'identity' AND OLD.id = NEW.id AND (
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

      INSERT INTO identity_history (
        history_id, id_type, id_number, full_name, date_of_birth,
        place_of_birth, nationality, issuing_authority,
        issue_date, expiry_date, mrz, scan_attachment_id,
        photo_attachment_id, notes, verified
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        i.id_type, i.id_number, i.full_name, i.date_of_birth,
        i.place_of_birth, i.nationality, i.issuing_authority,
        i.issue_date, i.expiry_date, i.mrz, i.scan_attachment_id,
        i.photo_attachment_id, i.notes, i.verified
      FROM identity_items i
      WHERE i.item_id = OLD.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS identity_fields_update_history
    AFTER UPDATE ON identity_items
    FOR EACH ROW
    WHEN (
      OLD.id_type != NEW.id_type OR
      OLD.id_number != NEW.id_number OR
      OLD.full_name IS NOT NEW.full_name OR
      OLD.date_of_birth IS NOT NEW.date_of_birth OR
      OLD.place_of_birth IS NOT NEW.place_of_birth OR
      OLD.nationality IS NOT NEW.nationality OR
      OLD.issuing_authority IS NOT NEW.issuing_authority OR
      OLD.issue_date IS NOT NEW.issue_date OR
      OLD.expiry_date IS NOT NEW.expiry_date OR
      OLD.mrz IS NOT NEW.mrz OR
      OLD.scan_attachment_id IS NOT NEW.scan_attachment_id OR
      OLD.photo_attachment_id IS NOT NEW.photo_attachment_id OR
      OLD.notes IS NOT NEW.notes OR
      OLD.verified != NEW.verified
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

      INSERT INTO identity_history (
        history_id, id_type, id_number, full_name, date_of_birth,
        place_of_birth, nationality, issuing_authority,
        issue_date, expiry_date, mrz, scan_attachment_id,
        photo_attachment_id, notes, verified
      ) VALUES (
        (SELECT id FROM vault_item_history WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.id_type, OLD.id_number, OLD.full_name, OLD.date_of_birth,
        OLD.place_of_birth, OLD.nationality, OLD.issuing_authority,
        OLD.issue_date, OLD.expiry_date, OLD.mrz, OLD.scan_attachment_id,
        OLD.photo_attachment_id, OLD.notes, OLD.verified
      );
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS identity_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'identity' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
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

      INSERT INTO identity_history (
        history_id, id_type, id_number, full_name, date_of_birth,
        place_of_birth, nationality, issuing_authority,
        issue_date, expiry_date, mrz, scan_attachment_id,
        photo_attachment_id, notes, verified
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        i.id_type, i.id_number, i.full_name, i.date_of_birth,
        i.place_of_birth, i.nationality, i.issuing_authority,
        i.issue_date, i.expiry_date, i.mrz, i.scan_attachment_id,
        i.photo_attachment_id, i.notes, i.verified
      FROM identity_items i
      WHERE i.item_id = OLD.id;
    END;
  ''',
];

const List<String> identitiesHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS identity_update_history;',
  'DROP TRIGGER IF EXISTS identity_fields_update_history;',
  'DROP TRIGGER IF EXISTS identity_delete_history;',
];
