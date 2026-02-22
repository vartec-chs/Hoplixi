const List<String> contactsHistoryCreateTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS contact_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'contact' AND OLD.id = NEW.id AND (
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

      INSERT INTO contact_history (
        history_id,
        phone,
        email,
        company,
        job_title,
        address,
        website,
        birthday,
        is_emergency_contact,
        notes
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        c.phone,
        c.email,
        c.company,
        c.job_title,
        c.address,
        c.website,
        c.birthday,
        c.is_emergency_contact,
        c.notes
      FROM contact_items c
      WHERE c.item_id = OLD.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS contact_fields_update_history
    AFTER UPDATE ON contact_items
    FOR EACH ROW
    WHEN (
      OLD.phone IS NOT NEW.phone OR
      OLD.email IS NOT NEW.email OR
      OLD.company IS NOT NEW.company OR
      OLD.job_title IS NOT NEW.job_title OR
      OLD.address IS NOT NEW.address OR
      OLD.website IS NOT NEW.website OR
      OLD.birthday IS NOT NEW.birthday OR
      OLD.is_emergency_contact != NEW.is_emergency_contact OR
      OLD.notes IS NOT NEW.notes
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

      INSERT INTO contact_history (
        history_id,
        phone,
        email,
        company,
        job_title,
        address,
        website,
        birthday,
        is_emergency_contact,
        notes
      ) VALUES (
        (SELECT id FROM vault_item_history WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.phone,
        OLD.email,
        OLD.company,
        OLD.job_title,
        OLD.address,
        OLD.website,
        OLD.birthday,
        OLD.is_emergency_contact,
        OLD.notes
      );
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS contact_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'contact' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
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

      INSERT INTO contact_history (
        history_id,
        phone,
        email,
        company,
        job_title,
        address,
        website,
        birthday,
        is_emergency_contact,
        notes
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        c.phone,
        c.email,
        c.company,
        c.job_title,
        c.address,
        c.website,
        c.birthday,
        c.is_emergency_contact,
        c.notes
      FROM contact_items c
      WHERE c.item_id = OLD.id;
    END;
  ''',
];

const List<String> contactsHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS contact_update_history;',
  'DROP TRIGGER IF EXISTS contact_fields_update_history;',
  'DROP TRIGGER IF EXISTS contact_delete_history;',
];
