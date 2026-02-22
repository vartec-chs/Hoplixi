const List<String> sshKeysHistoryCreateTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS ssh_key_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'sshKey' AND OLD.id = NEW.id AND (
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

      INSERT INTO ssh_key_history (
        history_id, public_key, private_key, key_type, key_size, passphrase_hint,
        comment, fingerprint, created_by, added_to_agent, usage,
        public_key_file_id, private_key_file_id, metadata
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        s.public_key, s.private_key, s.key_type, s.key_size, s.passphrase_hint,
        s.comment, s.fingerprint, s.created_by, s.added_to_agent, s.usage,
        s.public_key_file_id, s.private_key_file_id, s.metadata
      FROM ssh_key_items s
      WHERE s.item_id = OLD.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS ssh_key_fields_update_history
    AFTER UPDATE ON ssh_key_items
    FOR EACH ROW
    WHEN (
      OLD.public_key != NEW.public_key OR
      OLD.private_key != NEW.private_key OR
      OLD.key_type IS NOT NEW.key_type OR
      OLD.key_size IS NOT NEW.key_size OR
      OLD.passphrase_hint IS NOT NEW.passphrase_hint OR
      OLD.comment IS NOT NEW.comment OR
      OLD.fingerprint IS NOT NEW.fingerprint OR
      OLD.created_by IS NOT NEW.created_by OR
      OLD.added_to_agent != NEW.added_to_agent OR
      OLD.usage IS NOT NEW.usage OR
      OLD.public_key_file_id IS NOT NEW.public_key_file_id OR
      OLD.private_key_file_id IS NOT NEW.private_key_file_id OR
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

      INSERT INTO ssh_key_history (
        history_id, public_key, private_key, key_type, key_size, passphrase_hint,
        comment, fingerprint, created_by, added_to_agent, usage,
        public_key_file_id, private_key_file_id, metadata
      ) VALUES (
        (SELECT id FROM vault_item_history WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.public_key, OLD.private_key, OLD.key_type, OLD.key_size,
        OLD.passphrase_hint, OLD.comment, OLD.fingerprint, OLD.created_by,
        OLD.added_to_agent, OLD.usage, OLD.public_key_file_id,
        OLD.private_key_file_id, OLD.metadata
      );
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS ssh_key_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'sshKey' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
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

      INSERT INTO ssh_key_history (
        history_id, public_key, private_key, key_type, key_size, passphrase_hint,
        comment, fingerprint, created_by, added_to_agent, usage,
        public_key_file_id, private_key_file_id, metadata
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        s.public_key, s.private_key, s.key_type, s.key_size, s.passphrase_hint,
        s.comment, s.fingerprint, s.created_by, s.added_to_agent, s.usage,
        s.public_key_file_id, s.private_key_file_id, s.metadata
      FROM ssh_key_items s
      WHERE s.item_id = OLD.id;
    END;
  ''',
];

const List<String> sshKeysHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS ssh_key_update_history;',
  'DROP TRIGGER IF EXISTS ssh_key_fields_update_history;',
  'DROP TRIGGER IF EXISTS ssh_key_delete_history;',
];
