const List<String> recoveryCodesHistoryCreateTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS recovery_codes_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'recoveryCodes' AND OLD.id = NEW.id AND (
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

      INSERT INTO recovery_codes_history (
        history_id, codes_blob, codes_count, used_count, per_code_status,
        generated_at, one_time, display_hint
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        r.codes_blob, r.codes_count, r.used_count, r.per_code_status,
        r.generated_at, r.one_time, r.display_hint
      FROM recovery_codes_items r
      WHERE r.item_id = OLD.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS recovery_codes_fields_update_history
    AFTER UPDATE ON recovery_codes_items
    FOR EACH ROW
    WHEN (
      OLD.codes_blob != NEW.codes_blob OR
      OLD.codes_count IS NOT NEW.codes_count OR
      OLD.used_count IS NOT NEW.used_count OR
      OLD.per_code_status IS NOT NEW.per_code_status OR
      OLD.generated_at IS NOT NEW.generated_at OR
      OLD.one_time != NEW.one_time OR
      OLD.display_hint IS NOT NEW.display_hint
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

      INSERT INTO recovery_codes_history (
        history_id, codes_blob, codes_count, used_count, per_code_status,
        generated_at, one_time, display_hint
      ) VALUES (
        (SELECT id FROM vault_item_history WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.codes_blob, OLD.codes_count, OLD.used_count, OLD.per_code_status,
        OLD.generated_at, OLD.one_time, OLD.display_hint
      );
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS recovery_codes_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'recoveryCodes' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
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

      INSERT INTO recovery_codes_history (
        history_id, codes_blob, codes_count, used_count, per_code_status,
        generated_at, one_time, display_hint
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        r.codes_blob, r.codes_count, r.used_count, r.per_code_status,
        r.generated_at, r.one_time, r.display_hint
      FROM recovery_codes_items r
      WHERE r.item_id = OLD.id;
    END;
  ''',
];

const List<String> recoveryCodesHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS recovery_codes_update_history;',
  'DROP TRIGGER IF EXISTS recovery_codes_fields_update_history;',
  'DROP TRIGGER IF EXISTS recovery_codes_delete_history;',
];
