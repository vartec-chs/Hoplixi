const List<String> cryptoWalletsHistoryCreateTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS crypto_wallet_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'cryptoWallet' AND OLD.id = NEW.id AND (
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

      INSERT INTO crypto_wallet_history (
        history_id, wallet_type, mnemonic, private_key, derivation_path,
        network, addresses, xpub, xprv, hardware_device,
        last_balance_checked_at, notes_on_usage, watch_only, derivation_scheme
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        c.wallet_type, c.mnemonic, c.private_key, c.derivation_path,
        c.network, c.addresses, c.xpub, c.xprv, c.hardware_device,
        c.last_balance_checked_at, c.notes_on_usage, c.watch_only,
        c.derivation_scheme
      FROM crypto_wallet_items c
      WHERE c.item_id = OLD.id;
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS crypto_wallet_fields_update_history
    AFTER UPDATE ON crypto_wallet_items
    FOR EACH ROW
    WHEN (
      OLD.wallet_type != NEW.wallet_type OR
      OLD.mnemonic IS NOT NEW.mnemonic OR
      OLD.private_key IS NOT NEW.private_key OR
      OLD.derivation_path IS NOT NEW.derivation_path OR
      OLD.network IS NOT NEW.network OR
      OLD.addresses IS NOT NEW.addresses OR
      OLD.xpub IS NOT NEW.xpub OR
      OLD.xprv IS NOT NEW.xprv OR
      OLD.hardware_device IS NOT NEW.hardware_device OR
      OLD.last_balance_checked_at IS NOT NEW.last_balance_checked_at OR
      OLD.notes_on_usage IS NOT NEW.notes_on_usage OR
      OLD.watch_only != NEW.watch_only OR
      OLD.derivation_scheme IS NOT NEW.derivation_scheme
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

      INSERT INTO crypto_wallet_history (
        history_id, wallet_type, mnemonic, private_key, derivation_path,
        network, addresses, xpub, xprv, hardware_device,
        last_balance_checked_at, notes_on_usage, watch_only, derivation_scheme
      ) VALUES (
        (SELECT id FROM vault_item_history WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.wallet_type, OLD.mnemonic, OLD.private_key, OLD.derivation_path,
        OLD.network, OLD.addresses, OLD.xpub, OLD.xprv, OLD.hardware_device,
        OLD.last_balance_checked_at, OLD.notes_on_usage, OLD.watch_only,
        OLD.derivation_scheme
      );
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS crypto_wallet_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'cryptoWallet' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
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

      INSERT INTO crypto_wallet_history (
        history_id, wallet_type, mnemonic, private_key, derivation_path,
        network, addresses, xpub, xprv, hardware_device,
        last_balance_checked_at, notes_on_usage, watch_only, derivation_scheme
      )
      SELECT
        (SELECT id FROM vault_item_history WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        c.wallet_type, c.mnemonic, c.private_key, c.derivation_path,
        c.network, c.addresses, c.xpub, c.xprv, c.hardware_device,
        c.last_balance_checked_at, c.notes_on_usage, c.watch_only,
        c.derivation_scheme
      FROM crypto_wallet_items c
      WHERE c.item_id = OLD.id;
    END;
  ''',
];

const List<String> cryptoWalletsHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS crypto_wallet_update_history;',
  'DROP TRIGGER IF EXISTS crypto_wallet_fields_update_history;',
  'DROP TRIGGER IF EXISTS crypto_wallet_delete_history;',
];
