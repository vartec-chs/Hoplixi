const List<String> certificatesHistoryCreateTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS certificate_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'certificate' AND OLD.id = NEW.id AND (
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

      INSERT INTO certificate_history (
        history_id, certificate_pem, private_key, serial_number, issuer, subject,
        valid_from, valid_to, fingerprint, key_usage, extensions, pfx_blob,
        password_for_pfx, ocsp_url, crl_url, auto_renew, last_checked_at
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        c.certificate_pem, c.private_key, c.serial_number, c.issuer, c.subject,
        c.valid_from, c.valid_to, c.fingerprint, c.key_usage, c.extensions,
        c.pfx_blob, c.password_for_pfx, c.ocsp_url, c.crl_url, c.auto_renew,
        c.last_checked_at
      FROM certificate_items c
      WHERE c.item_id = OLD.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS certificate_fields_update_history
    AFTER UPDATE ON certificate_items
    FOR EACH ROW
    WHEN (
      OLD.certificate_pem != NEW.certificate_pem OR
      OLD.private_key IS NOT NEW.private_key OR
      OLD.serial_number IS NOT NEW.serial_number OR
      OLD.issuer IS NOT NEW.issuer OR
      OLD.subject IS NOT NEW.subject OR
      OLD.valid_from IS NOT NEW.valid_from OR
      OLD.valid_to IS NOT NEW.valid_to OR
      OLD.fingerprint IS NOT NEW.fingerprint OR
      OLD.key_usage IS NOT NEW.key_usage OR
      OLD.extensions IS NOT NEW.extensions OR
      OLD.pfx_blob IS NOT NEW.pfx_blob OR
      OLD.password_for_pfx IS NOT NEW.password_for_pfx OR
      OLD.ocsp_url IS NOT NEW.ocsp_url OR
      OLD.crl_url IS NOT NEW.crl_url OR
      OLD.auto_renew != NEW.auto_renew OR
      OLD.last_checked_at IS NOT NEW.last_checked_at
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

      INSERT INTO certificate_history (
        history_id, certificate_pem, private_key, serial_number, issuer, subject,
        valid_from, valid_to, fingerprint, key_usage, extensions, pfx_blob,
        password_for_pfx, ocsp_url, crl_url, auto_renew, last_checked_at
      ) VALUES (
        (SELECT id FROM vault_item_history WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.certificate_pem, OLD.private_key, OLD.serial_number, OLD.issuer,
        OLD.subject, OLD.valid_from, OLD.valid_to, OLD.fingerprint,
        OLD.key_usage, OLD.extensions, OLD.pfx_blob, OLD.password_for_pfx,
        OLD.ocsp_url, OLD.crl_url, OLD.auto_renew, OLD.last_checked_at
      );
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS certificate_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'certificate' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
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

      INSERT INTO certificate_history (
        history_id, certificate_pem, private_key, serial_number, issuer, subject,
        valid_from, valid_to, fingerprint, key_usage, extensions, pfx_blob,
        password_for_pfx, ocsp_url, crl_url, auto_renew, last_checked_at
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        c.certificate_pem, c.private_key, c.serial_number, c.issuer, c.subject,
        c.valid_from, c.valid_to, c.fingerprint, c.key_usage, c.extensions,
        c.pfx_blob, c.password_for_pfx, c.ocsp_url, c.crl_url, c.auto_renew,
        c.last_checked_at
      FROM certificate_items c
      WHERE c.item_id = OLD.id;
    END;
  ''',
];

const List<String> certificatesHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS certificate_update_history;',
  'DROP TRIGGER IF EXISTS certificate_fields_update_history;',
  'DROP TRIGGER IF EXISTS certificate_delete_history;',
];
